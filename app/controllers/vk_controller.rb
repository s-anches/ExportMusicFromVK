class VkController < ApplicationController

	def index
		console

		if session[:token] && session[:expires] && DateTime.current.to_i < session[:expires]
			@vk = VK::Client.new(session[:token])

			@user = @vk.users.get(user_ids: session[:user_id])
			@music = @vk.audio.get(owner_id: session[:user_id])
		end
	end

	def new
		session[:state] = Digest::MD5.hexdigest(rand.to_s)

		redirect_to VK.authorization_url(scope: [:friends, :audio, :wall], state: session[:state])
	end

	def create
		redirect_to root_url, alert: 'Ошибка авторизации!' if params[:state] != session[:state]

		vk = VkontakteApi.authorize(code: params[:code])

		session[:user_id] = vk.user_id
		session[:token] = vk.token
		session[:expires] = vk.expires_at.to_i

		redirect_to root_url, alert: "Вы успешно авторизированны!"
	end

	def destroy
		redirect_to root_url, alert: "Вы успешно вышли!" if session.clear
	end

	def get_audio
	end

end
