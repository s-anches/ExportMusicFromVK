require 'open-uri'

class VkController < ApplicationController

	HTTP_ERRORS = [
	  EOFError,
	  Errno::ECONNRESET,
	  Errno::EINVAL,
	  Net::HTTPBadResponse,
	  Net::HTTPHeaderSyntaxError,
	  Net::ProtocolError,
	  Timeout::Error
	]

	def index
		console

		check_authorization
	end

	def new
		session[:state] = Digest::MD5.hexdigest(rand.to_s)

		redirect_to VK.authorization_url(scope: [:friends, :audio, :wall], state: session[:state])
	end

	def create
		redirect_to root_url, alert: 'Ошибка авторизации!' if params[:state] != session[:state]
		redirect_to root_url, alert: '#{params[:error]} #{params[:error_description]}' if params[:error]

		if params[:code]
			vk = VK.authorize(code: params[:code])

			session[:user_id]	= vk.user_id
			session[:token]		= vk.token
			session[:expires]	= vk.expires_at.to_i

			redirect_to root_url, alert: "Вы успешно авторизированны!"
		else
			redirect_to root_url, alert: "Произошла неведомая ошибка. Попробуйте еще раз!"
		end
	end

	def destroy
		redirect_to root_url, alert: "Вы успешно вышли!" if session.clear
	end

	def get_audio
		check_authorization
		@music = @vk.audio.get(owner_id: session[:user_id])
		respond_to do |format|
			format.html { render partial: "music" }
      format.json { render json: @music }
  	end
	end

	def save_file
		id = params[:id].to_i
		if id < 10
			track_id = "000#{id}"
		elsif id >= 10 && id < 100
			track_id = "00#{id}"
		elsif id >= 100 && id < 1000
			track_id = "0#{id}"
		end

		file_name = "#{track_id}. #{params[:artist]} - #{params[:title]}.mp3"
		begin
			if File.exist? file_name
				respond_to do |format|
		      format.json { render json: {:status => "File exist", :id => id} }
		  	end
		  else
				open(file_name, 'wb') do |file|
		  		file << open(params[:url]).read
				end
				respond_to do |format|
		      format.json { render json: {:status => "File created", :id => id} }
		  	end
			end
		rescue => error
			respond_to do |format|
	      format.json { render json: {:status => error.inspect, :id => id} }
	  	end
  	end
	end

	def save_all
		check_authorization
		musics = @vk.audio.get(owner_id: session[:user_id])

		id = 1
		status = {}

		musics.each do |music|
			if id < 10
				track_id = "000#{id}"
			elsif id >= 10 && id < 100
				track_id = "00#{id}"
			elsif id >= 100 && id < 1000
				track_id = "0#{id}"
			else
				track_id = id
			end
			if music.respond_to?(:artist) && music.respond_to?(:title) && music.respond_to?(:url)
				artist = music.artist.delete "*|\\:\"<>?/"
				title = music.title.delete "*|\\:\"<>?/"
				file_name = "#{track_id}. #{artist} - #{title}.mp3"
				begin
					if File.exist? file_name
						status.store(id, "Exist")
					else
						open(file_name, 'wb') do |file|
				  		file << open(music.url).read
						end
						status.store(id, "Saved")
				  end
				rescue => error
					status.store(id, "ERROR")
				end
				id += 1
			end
		end
		respond_to do |format|
      format.json { render json: status }
  	end
	end

	private

		def check_authorization
			if session[:token] && session[:expires] && DateTime.current.to_i < session[:expires]
				@vk = VK::Client.new(session[:token])
				@user = @vk.users.get(user_ids: session[:user_id])
			end
		end

end
