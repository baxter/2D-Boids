root = this

root.number         = 20
root.width          = 830
root.height         = 430
root.wrap_around    = 20
root.nearby_dist    = 100
root.too_close_dist = 20

root.draw_between_nearby = false
root.draw_debug = false
root.match_direction = true

initialised = false

root.start = () ->
  unless initialised
    root.canvas   = document.getElementById "boids"
    root.context  = canvas.getContext "2d"
    root.boids    = (new Boid(n) for n in [0...root.number]) # [new Boid, new Boid, new Boid]
    initialised   = true
  
  frame = () ->
    _.each(root.boids, (b) ->
      neighbours = near_to(b)
      if match_direction
        avg_direction = average(_.collect(neighbours, (neighbour) -> neighbour.direction))
        b.rotate_towards(avg_direction)
      
      # Move the boids
      b.move()
    )
    # Draw the boids
    root.draw(context, root.boids)
  
  @intervalId = setInterval(frame, 20)

root.stop = () ->
  clearInterval @intervalId

root.reset = () ->
  root.stop()
  initialised = false
  root.draw(root.context, [])

root.draw = (context, boids) ->
  context.clearRect(0,0,root.width,root.height)
  _.each(boids, (b) -> b.draw(context))

root.near_to = (target) ->
  _.filter(root.boids, (boid) ->
    boid.id != target.id && (distance_between(target, boid) < root.nearby_dist)
  )

root.distance_between = (a, b) ->
  dx = Math.abs(a.x - b.x)
  dy = Math.abs(a.y - b.y)
  Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2))

root.average = (array) ->
  _.reduce(array, ((memo, element) -> memo + element), 0) / array.length

class Boid
  constructor: (@id) ->
    @x = Math.random() * root.width
    @y = Math.random() * root.height
    @direction = Math.random() * Math.PI * 2
    @speed = 2
    @direction_change_speed = 0.005
  
  draw: (context) ->
    
    # Draw lines between nearby boids
    if draw_between_nearby
      context.save()
      context.beginPath()
      _.each(near_to(this),
        (boid) ->
          unless boid.id > this.id # This is to prevent drawing multiple lines between the same two boids
            context.strokeStyle = "lawngreen"
            context.moveTo(this.x, this.y)
            context.lineTo(boid.x, boid.y)
            context.stroke()
        , this
      )
      context.closePath()
      context.restore()
    
    context.save()
    # Move to the appropriate location
    context.translate(@x, @y)
    # Draw some explanatory text
    if draw_debug
      context.fillStyle = "darkgray"
      context.fillText("i: #{@id}", 15, -6)
      context.fillText("x: #{Math.round(@x)}", 15, 3)
      context.fillText("y: #{Math.round(@y)}", 15, 13)
    context.fillStyle = "black"
    context.strokeStyle = "black"
    # Rotate to the appropriate direction
    context.rotate(@direction)
    # Draw the arrow shape
    context.beginPath()
    context.moveTo(10, 0)
    context.lineTo(-10, 6)
    context.lineTo(-6, 0)
    context.lineTo(-10, -6)
    context.closePath()
    context.fill()
    context.restore()
    
  
  move: () ->
    @x += Math.cos(@direction) * @speed
    @y += Math.sin(@direction) * @speed
    if @x > root.width + root.wrap_around
      @x = -root.wrap_around
    if @y > root.height + root.wrap_around
      @y = -root.wrap_around
    if @x < -root.wrap_around
      @x = root.width + root.wrap_around
    if @y < -root.wrap_around
      @y = root.height + root.wrap_around
  
  rotate_towards: (direction) ->
    if direction > @direction
      @direction += @direction_change_speed
    if direction < @direction
      @direction -= @direction_change_speed
  
  move_away_from: (direction) ->
    if direction > @direction
      @direction -= @direction_change_speed
    if direction < @direction
      @direction += @direction_change_speed
    
  
  direction_degrees: () ->
    Math.floor(@direction * 57.2957795)