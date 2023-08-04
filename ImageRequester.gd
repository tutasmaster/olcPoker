extends HTTPRequest
class_name ImageRequest

signal image_retrieved
var url = ""

func request_image(location: String):
	request_completed.connect(_http_request_completed)
	url = location
	return super.request(location)

func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)
	if image_error != OK:
		print("An error occurred while trying to display the image.")
	print(image.get_size())
	var texture = ImageTexture.create_from_image(image)
	image_retrieved.emit(texture, url)
