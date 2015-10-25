# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $(".export").on("ajax:success", (e, data, status, xhr) ->
    $("#export").html xhr.responseText
   ).on "ajax:error", (e, xhr, status, error) ->
    console.log("Error")

  $("#save_track").on("ajax:success", (e, data, status, xhr) ->
  	console.log("OK")
   ).on "ajax:error", (e, xhr, status, error) ->
   	console.log("Error")

  $("#export").on("ajax:success", "#save_track", (e, data, status, xhr) ->
  	if data.status == "File exist"
  		$('[data-id="'+data.id+'"] input:submit').css("background-color": "blue");
  	if data.status == "File created"
  		$('[data-id="'+data.id+'"] input:submit').css("background-color": "green");
   ).on "ajax:error", "#save_track", (e, xhr, status, error) ->
   	console.log("TEST ERROR")