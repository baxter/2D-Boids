root = this

root.width    = 530
root.height   = 430
root.overlap  = 10

root.start = () ->
  canvas  = document.getElementById "boids"
  context = canvas.getContext "2d"
  boids = [new Boid]
  frame = () ->
    # Draw the boids
    root.draw(context, boids)
    # Move the boids
    _.each(boids, (b) -> b.move(boids))
  @intervalId = setInterval(frame, 20)

root.stop = () ->
  clearInterval @intervalId

root.draw = (context, boids) ->
  context.clearRect(0,0,root.width,root.height)
  _.each(boids, (b) -> b.draw(context))

class Boid
  constructor: () ->
    @x = 0
    @y = 0
    @direction = 0
  
  draw: (context) ->
    context.beginPath()
    context.arc(@x, @y, 10, 0, Math.PI*2, true)
    context.closePath()
    context.fill()
  
  move: (boids) ->
    @x -= 3
    @y -= 3
    if @x > root.width + root.overlap
      @x = -root.overlap
    if @y > root.height + root.overlap
      @y = -root.overlap
    if @x < -root.overlap
      @x = root.width + root.overlap
    if @y < -root.overlap
      @y = root.height + root.overlap