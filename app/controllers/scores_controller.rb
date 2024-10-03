module Api
  class ScoresController < ApplicationController
    def show
      score = Score.find(params[:id])
      render json: { status: 'success', data: score.xml_data }
    rescue ActiveRecord::RecordNotFound
      render json: { status: 'error', message: 'Score not found' }, status: :not_found
    end

    def update
      score = Score.find(params[:id])
      if score.update(xml_data: params[:xml_data])
        render json: { status: 'updated', score_id: score.id }
      else
        render json: { status: 'error', message: score.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { status: 'error', message: 'Score not found' }, status: :not_found
    end

    def destroy
      score = Score.find(params[:id])
      score.destroy
      render json: { status: 'deleted', score_id: params[:id] }
    rescue ActiveRecord::RecordNotFound
      render json: { status: 'error', message: 'Score not found' }, status: :not_found
    end
  end
end