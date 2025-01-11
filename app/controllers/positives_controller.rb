# app/controllers/positives_controller.rb
class PositivesController < ApplicationController
  before_action :set_positive, only: %i[ show update destroy ]

  require 'csv'

  # GET /positives or /positives.json
  def index
    # 基本のポジティブデータを取得
    @positives = Positive.all
    @positive_counts_by_month = Positive.group_by_month(:created_at).sum(:count)
  
    # フィルタリング用の場所の取得
    @places = Positive.select(:place).distinct.pluck(:place)
  
    # 場所によるフィルタリング
    if params[:places].present?
      @positives = @positives.where(place: params[:places])
    end
  
    # 開始日と終了日のパラメータを取得してフィルタリング
    if params[:start_year].present? && params[:start_month].present? && params[:start_day].present?
      start_date = Date.new(params[:start_year].to_i, params[:start_month].to_i, params[:start_day].to_i)
      @positives = @positives.where("created_at >= ?", start_date)
    end
  
    if params[:end_year].present? && params[:end_month].present? && params[:end_day].present?
      end_date = Date.new(params[:end_year].to_i, params[:end_month].to_i, params[:end_day].to_i)
      @positives = @positives.where("created_at <= ?", end_date)
    end
  
    # ページネーションを適用
    @items = @positives.order(created_at: :asc).page(params[:page]).per(5)

    # 場所ごとのポジティブワードの合計カウントを計算
    @place_counts = @positives.group(:place).sum(:count)


    # その他の変数（例：場所一覧）
    @places = Positive.select(:place).distinct.pluck(:place)

    


  end
  

  # GET /positives/1 or /positives/1.json
  def show
  end

  # GET /positives/new
  def new
  end

  # GET /positives/1/edit
  def edit
   
  end

  # POST /positives or /positives.json
  def create
    @positive = Positive.new(positive_params)

    respond_to do |format|
      if @positive.save
        format.html { redirect_to @positive, notice: "Positive was successfully created." }
        format.json { render :show, status: :created, location: @positive }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @positive.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /positives/1 or /positives/1.json
  def update
    respond_to do |format|
      if @positive.update(positive_params)
        format.html { redirect_to @positive, notice: "Positive was successfully updated." }
        format.json { render :show, status: :ok, location: @positive }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @positive.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /positives/1 or /positives/1.json
  def destroy
    @positive.destroy!

    respond_to do |format|
      format.html { redirect_to positives_path, status: :see_other, notice: "Positive was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # POST /positives/upload_csv
  def upload_csv
    file = params[:csv_file]
    place = params[:place]
  
    # CSVがアップロードされていることを確認
    if file.nil?
      flash[:alert] = "CSVファイルを選択してください。"
      redirect_to positives_path
      return
    end
  
    # CSVファイルを読み込む
    begin
      csv_content = File.read(file.path, encoding: 'Shift_JIS:UTF-8')  # エンコーディング変換
      CSV.parse(csv_content, headers: true) do |row|
        word = row['word']
        count = row['count']
        
        # 読み込んだデータをログに出力して確認
        Rails.logger.debug "読み込んだ word: #{word}, count: #{count}"
  
        # Positiveモデルにデータを保存
        positive = Positive.create!(
          word: word,
          count: count.to_i,  # countを整数に変換して保存
          place: place,
          datetime: DateTime.now  # 現在の日付
        )
  
        # 保存したデータをログに出力
        Rails.logger.debug "保存したデータ: #{positive.inspect}"
      end
  
      flash[:notice] = "CSVファイルが正常にアップロードされました。"
    rescue => e
      flash[:alert] = "エラーが発生しました: #{e.message}"
    end
  
    redirect_to positives_path
  end

  def employee
    # 検索した日付を取得（今日は今日の日付と仮定）
    search_date = Date.today

    # 1週間前の日付を取得
    one_week_ago = search_date - 7.days

    # 色を個別に設定（例）
    @circle_colors = ['#CDD2EE', '#C9E8F0', '#EEC3DB', '#EEC3DB', '#CDD2EE', '#C9E8F0']
    # 他の必要なインスタンス変数設定

    @location_colors = ['#CDD2EE', '#C9E8F0', '#EEC3DB', '#EEC3DB', '#CDD2EE', '#C9E8F0']

    # データベースからユニークな場所（place）を取得
    @locations = Positive.distinct.pluck(:place)

    # 各場所ごとに感謝ワードの集計
    @positive_counts = {}
    @locations.each do |place|
      # 1週間前から今日まで、指定された場所ごとの感謝ワードを集計
      word_counts = Positive.where(place: place, created_at: one_week_ago..search_date)
                             .group(:word)
                             .order('SUM(count) DESC')
                             .limit(3) # トップ3のワードを取得
                             .select(:word, 'SUM(count) AS total_count')

      @positive_counts[place] = word_counts
    end

    @positive_counts_last_week = get_last_week_counts
    @positive_counts_today = get_today_counts

    # 各場所の増減を計算
    @location_changes = calculate_percentage_change(@positive_counts_last_week, @positive_counts_today)

    # 過去7日間のデータを日ごとに集計
    @graph_data = Positive.where("created_at >= ?", 7.days.ago)
                           .group_by_day(:created_at)
                           .sum(:count)

  end

  def employee2
    # 検索した日付を取得（今日は今日の日付と仮定）
    search_date = Date.today

    # 1週間前の日付を取得
    one_week_ago = search_date - 7.days

    # 色を個別に設定（例）
    @circle_colors = ['#CDD2EE', '#C9E8F0', '#EEC3DB', '#EEC3DB', '#CDD2EE', '#C9E8F0']
    # 他の必要なインスタンス変数設定

    @location_colors = ['#CDD2EE', '#C9E8F0', '#EEC3DB', '#EEC3DB', '#CDD2EE', '#C9E8F0']

    # データベースからユニークな場所（place）を取得
    @locations = Positive.distinct.pluck(:place)

    # 各場所ごとに感謝ワードの集計
    @positive_counts = {}
    @locations.each do |place|
      # 1週間前から今日まで、指定された場所ごとの感謝ワードを集計
      word_counts = Positive.where(place: place, created_at: one_week_ago..search_date)
                             .group(:word)
                             .order('SUM(count) DESC')
                             .limit(3) # トップ3のワードを取得
                             .select(:word, 'SUM(count) AS total_count')

      @positive_counts[place] = word_counts
    end

    @positive_counts_last_week = get_last_week_counts
    @positive_counts_today = get_today_counts

    # 各場所の増減を計算
    @location_changes = calculate_percentage_change(@positive_counts_last_week, @positive_counts_today)

    # 過去7日間のデータを日ごとに集計
    @graph_data = Positive.where("created_at >= ?", 7.days.ago)
                           .group_by_day(:created_at)
                           .sum(:count)

  end

  def site
    # 基本のポジティブデータを取得
    @positives = Positive.all
    @positive_counts_by_month = Positive.group_by_month(:created_at).sum(:count)
  
    # フィルタリング用の場所の取得
    @places = Positive.select(:place).distinct.pluck(:place)
  
    # 場所によるフィルタリング
    if params[:places].present?
      @positives = @positives.where(place: params[:places])
    end
  
    # 開始日と終了日のパラメータを取得してフィルタリング
    if params[:start_year].present? && params[:start_month].present? && params[:start_day].present?
      start_date = Date.new(params[:start_year].to_i, params[:start_month].to_i, params[:start_day].to_i)
      @positives = @positives.where("created_at >= ?", start_date)
    end
  
    if params[:end_year].present? && params[:end_month].present? && params[:end_day].present?
      end_date = Date.new(params[:end_year].to_i, params[:end_month].to_i, params[:end_day].to_i)
      @positives = @positives.where("created_at <= ?", end_date)
    end
  
    # ページネーションを適用
    @items = @positives.order(created_at: :asc).page(params[:page]).per(5)

    # 場所ごとのポジティブワードの合計カウントを計算
    @place_counts = @positives.group(:place).sum(:count)


    # その他の変数（例：場所一覧）
    @places = Positive.select(:place).distinct.pluck(:place)
 
    start_date = Date.new(params[:start_year].to_i, params[:start_month].to_i, params[:start_day].to_i) if params[:start_year] && params[:start_month] && params[:start_day]
    end_date = Date.new(params[:end_year].to_i, params[:end_month].to_i, params[:end_day].to_i) if params[:end_year] && params[:end_month] && params[:end_day]

    # 期間が指定されていれば、期間で絞り込み
    if start_date && end_date
      @items = Positive.where(created_at: start_date..end_date)
    else
      @items = Positive.all
    end

    # 場所ごとの集計データ
    @location_counts = @items.group(:place).count
      
    


  end

  def period
    # 基本のポジティブデータを取得
    @positives = Positive.all
    @positive_counts_by_month = Positive.group_by_month(:created_at).sum(:count)
  
    # フィルタリング用の場所の取得
    @places = Positive.select(:place).distinct.pluck(:place)
  
    # 場所によるフィルタリング
    if params[:places].present?
      @positives = @positives.where(place: params[:places])
    end
  
    # 開始日と終了日のパラメータを取得してフィルタリング
    if params[:start_year].present? && params[:start_month].present? && params[:start_day].present?
      start_date = Date.new(params[:start_year].to_i, params[:start_month].to_i, params[:start_day].to_i)
      @positives = @positives.where("created_at >= ?", start_date)
    end
  
    if params[:end_year].present? && params[:end_month].present? && params[:end_day].present?
      end_date = Date.new(params[:end_year].to_i, params[:end_month].to_i, params[:end_day].to_i)
      @positives = @positives.where("created_at <= ?", end_date)
    end

    @start_date = Date.new(params[:start_year].to_i, params[:start_month].to_i, params[:start_day].to_i) if params[:start_year].present?
    @end_date = Date.new(params[:end_year].to_i, params[:end_month].to_i, params[:end_day].to_i) if params[:end_year].present?
    @selected_places = params[:places] || []
  
    @items = Positive.all
  
    # 日付でフィルタリング
    if @start_date && @end_date
      @items = @items.where(created_at: @start_date..@end_date)
    end
  
    # 場所でフィルタリング
    if @selected_places.any?
      @items = @items.where(place: @selected_places)
    end
  
    @chart_data = @items.group("DATE(created_at)", :place)
                        .count
                        .group_by { |(date, place), _| place }
                        .map do |place, records|
                          { name: place, data: records.map { |(date, _), count| [date, count] }.to_h }
                        end

  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_positive
      @positive = Positive.find_by(id: params[:id])
      if @positive.nil?
        flash[:alert] = "指定されたポジティブワードが見つかりませんでした。"
        redirect_to positives_path
      end
    end

    # Only allow a list of trusted parameters through.
    def positive_params
      params.require(:positive).permit(:word, :count, :place, :datetime)
    end

    def get_last_week_counts
      Positive.where(created_at: 1.week.ago.beginning_of_week..1.week.ago.end_of_week)
              .group(:place)
              .sum(:count)
    end
  
    def get_today_counts
      Positive.where(created_at: Date.today.beginning_of_day..Date.today.end_of_day)
              .group(:place)
              .sum(:count)
    end
  
    def calculate_percentage_change(last_week_counts, today_counts)
      changes = {}
      
      @locations.each do |place|
        last_week_count = last_week_counts[place] || 0
        today_count = today_counts[place] || 0
  
        percentage_change = if last_week_count == 0
                              today_count == 0 ? 0 : 100
                            else
                              ((today_count - last_week_count).to_f / last_week_count) * 100
                            end
  
        changes[place] = {
          percentage_change: percentage_change.round(2),
          today_count: today_count
        }
      end
  
      changes
    end
end
