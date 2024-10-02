class ImagesController < ApplicationController
  def create
    render json: {image: "created"}
  end
end
