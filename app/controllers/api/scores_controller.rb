module Api
  class ScoresController < ApiController
    def index
      scores = Score.all
      render json: { status: 'success', data: scores }, status: :ok
    end

    def show
      score = Score.find(params[:id])
      if params[:format] == 'mxl'
        send_file score.file_path, type: 'application/vnd.recordare.musicxml+xml', disposition: 'attachment', filename: "score_#{score.id}.mxl"
      else
        render json: { status: 'success', data: score }, status: :ok
      end
    rescue ActiveRecord::RecordNotFound
      render json: { status: 'error', message: 'Score not found' }, status: :not_found
    end

    def update
      score = Score.find(params[:id])
      if params[:file].present?
        file = params[:file]
        file_path = Rails.root.join('public', 'scores', "score_#{score.id}.mxl")
        File.open(file_path, 'wb') do |f|
          f.write(file.read)
        end
        score.update(file_path: file_path.to_s)
      end
    
      if score.update(score_params)
        render json: { status: 'success', data: score }, status: :ok
      else
        render json: { status: 'error', message: score.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { status: 'error', message: 'Score not found' }, status: :not_found
    end

    def destroy
      score = Score.find(params[:id])
      score.destroy
      render json: { status: 'success', message: 'Score deleted' }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { status: 'error', message: 'Score not found' }, status: :not_found
    end

    def download
      score = Score.find(params[:id])
      send_file score.file_path, type: 'application/vnd.recordare.musicxml+xml', disposition: 'attachment', filename: "score_#{score.id}.mxl"
    rescue ActiveRecord::RecordNotFound
      render json: { status: 'error', message: 'Score not found' }, status: :not_found
    end

    private

    def score_params
      params.require(:score).permit(:xml_data, :file_path)
    end
    end
  end
end