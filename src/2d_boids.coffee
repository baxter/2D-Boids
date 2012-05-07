root = this

root.number         = 20
root.width          = 830
root.height         = 430
root.wrap_around    = 20
root.nearby_dist    = 100
root.too_close_dist = 25

root.draw_between_nearby = false
root.draw_debug = false
root.keep_distance = true
root.match_direction = true
root.random_speed = false

initialised = false

root.start = () ->
  unless initialised
    root.canvas   = document.getElementById "boids"
    root.context  = canvas.getContext "2d"
    root.boids    = (new Boid(n) for n in [0...root.number]) # [new Boid, new Boid, new Boid]
    initialised   = true
  
  frame = () ->
    # Update the boids
    _.each(root.boids, (b) ->
      # Find boids that are neighbours
      nearby = near_to(b, nearby_dist)
      # Find boids that are too close
      too_close = near_to(b, too_close_dist)
      
      # Boids want to move together, so match direction with nearby boids
      if match_direction
        b.rotate_towards(average_direction(nearby))
      
      # Boids want to keep their distance from each other, so move in the opposite direction of very close boids
      if keep_distance
        b.rotate_away_from(average_direction(too_close))
      
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

root.near_to = (target, distance=nearby_dist) ->
  _.filter(root.boids, (boid) ->
    boid.id != target.id && (distance_between(target, boid) < distance)
  )

root.distance_between = (a, b) ->
  dx = Math.abs(a.x - b.x)
  dy = Math.abs(a.y - b.y)
  Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2))

root.average = (array) ->
  _.reduce(array, ((memo, element) -> memo + element), 0) / array.length

root.average_direction = (array) ->
  average(_.collect(array, (element) -> element.direction))

# The boid itself, every boid has a random starting location and random starting direction.
# They also have a movement speed and a rotation speed

class Boid
  constructor: (@id) ->
    @x = Math.random() * root.width
    @y = Math.random() * root.height
    @direction = Math.random() * Math.PI * 2
    if random_speed
      @speed = (Math.random() * 2) + 1
    else
      @speed = 2
    @rotation_speed = 0.01
  
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
    
  # Rotate towards a particular direction.
  # Don't bother rotating if the direction is very similar to the current direction.
  # This helps to stop boids from flying in circles
  # Rotate towards moves at half the speed of rotate away from. The reason being that if we are moving away from a direction we are probably avoiding a collision, and it looks better
  
  rotate_towards: (direction) ->
    if (direction - @rotation_speed) < @direction < (direction + @rotation_speed)
      return @direction
    else if direction > @direction
      @direction += (@rotation_speed / 2.0)
    else if direction < @direction
      @direction -= (@rotation_speed / 2.0)
  
  rotate_away_from: (direction) ->
    if direction > @direction
      @direction -= @rotation_speed
    if direction < @direction
      @direction += @rotation_speed
  
  direction_degrees: () ->
    Math.floor(@direction * 57.2957795)