class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def render_errors
    render file: "#{Rails.root}/public/500.html", layout: false, status: :unprocessable_entity
  end
end
