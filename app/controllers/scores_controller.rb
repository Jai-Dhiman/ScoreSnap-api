module Api
  class ScoresController < ApplicationController
    def index
      scores = Score.all
      render json: { status: 'success', data: scores }, status: :ok
    end

    def show
      score = Score.find(params[:id])
      render json: { status: 'success', data: score }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { status: 'error', message: 'Score not found' }, status: :not_found
    end

    def update
      score = Score.find(params[:id])
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

    private

    def score_params
      params.require(:score).permit(:xml_data)
    end
  end
end