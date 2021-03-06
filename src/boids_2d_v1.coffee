root = this
root.boids_2d_v1 = {}

boids_2d_v1.number         = 30
boids_2d_v1.width          = 830
boids_2d_v1.height         = 530
boids_2d_v1.wrap_around    = 20
boids_2d_v1.nearby_dist    = 100
boids_2d_v1.too_close_dist = 30

boids_2d_v1.draw_between_nearby = false
boids_2d_v1.draw_debug = false

boids_2d_v1.boids_keep_distance = true
boids_2d_v1.boids_match_direction = true
boids_2d_v1.boids_move_toward_centre = true

boids_2d_v1.random_speed = false

initialised = false
started = false
canvas = context = boids = null

boids_2d_v1.init = () ->
  canvas   = document.getElementById "boids"
  context  = canvas.getContext "2d"
  boids_2d_v1.boids    = (new Boid(n) for n in [0...boids_2d_v1.number]) # [new Boid, new Boid, new Boid]
  boids_2d_v1.draw(context, boids_2d_v1.boids)
  initialised   = true

boids_2d_v1.start = () ->
  if started
    return false
  
  started = true  
  
  unless initialised
    boids_2d_v1.init()
  
  frame = () ->
    # Update the boids
    _.each(boids_2d_v1.boids, (b) ->
      # Find boids that are neighbours
      nearby = near_to(b, boids_2d_v1.nearby_dist)
      # Find boids that are too close
      too_close = near_to(b, boids_2d_v1.too_close_dist)
      
      # Boids want to move together, so match direction with nearby boids
      if boids_2d_v1.boids_match_direction
        b.rotate_towards(average_direction(nearby))
      
      # Boids want to keep their distance from each other, so move in the opposite direction of very close boids
      if boids_2d_v1.boids_keep_distance
        b.rotate_away_from(average_direction(too_close))
      
      # Boids want to move toward the centre of the flock, so move in the direction of the average of all boids
      if boids_2d_v1.boids_move_toward_centre
        b.rotate_towards(
          direction_of_location(
            b, average_location(b)
          )
        )
      
      # Move the boids
      b.move()
    )
    # Draw the boids
    boids_2d_v1.draw(context, boids_2d_v1.boids)
  
  @intervalId = setInterval(frame, 30)

boids_2d_v1.stop = () ->
  clearInterval @intervalId
  started = false

boids_2d_v1.reset = () ->
  boids_2d_v1.stop()
  boids_2d_v1.init()

boids_2d_v1.draw = (context=context, boids=boids_2d_v1.boids) ->
  context.clearRect(0,0,boids_2d_v1.width,boids_2d_v1.height)
  _.each(boids, (b) -> b.draw_nearby_lines(context)) if boids_2d_v1.draw_between_nearby
  _.each(boids, (b) -> b.draw(context))

boids_2d_v1.toggle = (property) ->
  if boids_2d_v1[property]
    boids_2d_v1[property] = false
  else
    boids_2d_v1[property] = true
  boids_2d_v1.draw(context)

# Returns all boids apart from target

boids_2d_v1.other_boids = (target) ->
  _.reject(boids_2d_v1.boids, (boid) -> boid.id == target.id)

# Find the distance between two objects, provided both objects have x and y properties  

distance_between = (a, b) ->
  dx = a.x - b.x
  dy = a.y - b.y
  Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2))

# Finds the average value of an array of numbers

average = (array) ->
  _.reduce(array, ((memo, element) -> memo + element), 0) / array.length

# Find the average direction of an array, provided all elements have a direction property

average_direction = (array) ->
  average(_.collect(array, (element) -> element.direction))

# Finds boids that are near target, excluding target

near_to = (target, distance=boids_2d_v1.nearby_dist) ->
  _.filter(boids_2d_v1.other_boids(target), (boid) ->
    distance_between(target, boid) < distance
  )

# Finds the average location of all boids, exluding target

average_location = (target) ->
  x = average(_.collect(boids_2d_v1.other_boids(target), (boid) -> boid.x ))
  y = average(_.collect(boids_2d_v1.other_boids(target), (boid) -> boid.y ))
  {
    "x": x,
    "y": y
  }

# Finds the direction of a location from entity to location

direction_of_location = (start, end) ->
  x = end.x - start.x
  y = end.y - start.y
  Math.atan2(y, x)

# The boid itself, every boid has a random starting location and random starting direction.
# They also have a movement speed and a rotation speed

class Boid
  constructor: (@id) ->
    @x = Math.random() * boids_2d_v1.width
    @y = Math.random() * boids_2d_v1.height
    @direction = Math.random() * Math.PI * 2
    if boids_2d_v1.random_speed
      @speed = (Math.random() * 2) + 1
    else
      @speed = 3
    @rotation_speed = 0.02
  
  draw: (context) ->
    
    context.save()
    # Move to the appropriate location
    context.translate(@x, @y)
    # Draw some explanatory text
    if boids_2d_v1.draw_debug
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
  
  draw_nearby_lines: (context) ->
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
  
  move: () ->
    @x += Math.cos(@direction) * @speed
    @y += Math.sin(@direction) * @speed
    if @x > boids_2d_v1.width + boids_2d_v1.wrap_around
      @x = -boids_2d_v1.wrap_around
    if @y > boids_2d_v1.height + boids_2d_v1.wrap_around
      @y = -boids_2d_v1.wrap_around
    if @x < -boids_2d_v1.wrap_around
      @x = boids_2d_v1.width + boids_2d_v1.wrap_around
    if @y < -boids_2d_v1.wrap_around
      @y = boids_2d_v1.height + boids_2d_v1.wrap_around
    
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