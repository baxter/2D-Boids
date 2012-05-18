root = this
root.boids_2d_v2 = {}

bds = root.boids_2d_v2

bds.number         = 40
bds.width          = 830
bds.height         = 530
bds.wrap_around    = 200
bds.nearby_dist    = 50
bds.too_close_dist = 10
bds.mid_point      = { "x": bds.width / 2.0, "y": bds.height / 2.0 }

bds.draw_between_nearby = false
bds.draw_debug = false

bds.boids_keep_distance = true
bds.boids_match_direction = true
bds.boids_move_toward_centre = true

bds.random_speed = false

initialised = false
started = false
canvas = context = boids = null

bds.init = () ->
  canvas   = document.getElementById "boids"
  context  = canvas.getContext "2d"
  bds.boids    = (new Boid(n) for n in [0...bds.number]) # [new Boid, new Boid, new Boid]
  bds.draw(context, bds.boids)
  initialised   = true

bds.start = () ->
  if started
    return false
  
  started = true  
  
  unless initialised
    bds.init()
  
  frame = () ->
    # Update the boids
    _.each(bds.boids, (b) ->
      # Find boids that are neighbours
      nearby = near_to(b, bds.nearby_dist)
      # Find boids that are too close
      too_close = near_to(b, bds.too_close_dist)
      
      # Boids want to stay in the centre of the screen
      b.rotate_towards(direction_of_location(b, bds.mid_point), 0.125)
      
      # Boids want to move together, so match direction with nearby boids
      if bds.boids_match_direction
        b.rotate_towards(average_direction(nearby), 0.5)
  
      # Boids want to keep their distance from each other, so move in the opposite direction of very close boids
      if bds.boids_keep_distance
        b.rotate_away_from(average_direction(too_close), 1.0)
  
      # Boids want to move toward the centre of the flock, so move in the direction of the average of all boids
      if bds.boids_move_toward_centre
        b.rotate_towards(
          direction_of_location(
            b, average_location(b)
          ) , 0.25
        )
      
      # Move the boids
      b.move()
    )
    # Draw the boids
    bds.draw(context, bds.boids)
  
  @intervalId = setInterval(frame, 30)

bds.stop = () ->
  clearInterval @intervalId
  started = false

bds.reset = () ->
  bds.stop()
  bds.init()

bds.draw = (context=context, boids=bds.boids) ->
  context.clearRect(0,0,bds.width,bds.height)
  context.beginPath()
  context.arc(bds.mid_point.x, bds.mid_point.y, 4, 0, Math.PI * 2)
  context.fillStyle = "red"
  context.fill()
  context.closePath()
  _.each(boids, (b) -> b.draw_nearby_lines(context)) if bds.draw_between_nearby
  _.each(boids, (b) -> b.draw(context))

bds.toggle = (property) ->
  if bds[property]
    bds[property] = false
  else
    bds[property] = true
  bds.draw(context)

# Returns all boids apart from target

bds.other_boids = (target) ->
  _.reject(bds.boids, (boid) -> boid.id == target.id)

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

near_to = (target, distance=bds.nearby_dist) ->
  _.filter(bds.other_boids(target), (boid) ->
    distance_between(target, boid) < distance
  )

# Finds the average location of all boids, exluding target

average_location = (target) ->
  x = average(_.collect(bds.other_boids(target), (boid) -> boid.x ))
  y = average(_.collect(bds.other_boids(target), (boid) -> boid.y ))
  {
    "x": x,
    "y": y
  }

# Finds the direction of a location from entity to location

direction_of_location = (start, end) ->
  x = end.x - start.x
  y = end.y - start.y
  Math.atan2(y, x)

angle_difference = (start, end) ->
  diff = (end - start) % (Math.PI * 2) # The difference, and if it's over or under PI, modulus it
  diff -= Math.PI * 2 if diff > Math.PI
  diff += Math.PI * 2 if diff < -Math.PI
  diff

# The boid itself, every boid has a random starting location and random starting direction.
# They also have a movement speed and a rotation speed

class Boid
  constructor: (@id) ->
    @x = Math.random() * bds.width
    @y = Math.random() * bds.height
    @direction = Math.random() * Math.PI * 2
    if bds.random_speed
      @speed = (Math.random() * 2) + 1
    else
      @speed = 1
    @rotation_speed = 0.02
  
  draw: (context) ->
    
    context.save()
    # Move to the appropriate location
    context.translate(@x, @y)
    # Draw some explanatory text
    if bds.draw_debug
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
    context.moveTo(5, 0)
    context.lineTo(-5, 3)
    context.lineTo(-3, 0)
    context.lineTo(-5, -3)
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
    if @x > bds.width + bds.wrap_around
      @x = -bds.wrap_around
    if @y > bds.height + bds.wrap_around
      @y = -bds.wrap_around
    if @x < -bds.wrap_around
      @x = bds.width + bds.wrap_around
    if @y < -bds.wrap_around
      @y = bds.height + bds.wrap_around
    
  # Rotate towards a particular direction.
  # Don't bother rotating if the direction is very similar to the current direction.
  # This helps to stop boids from flying in circles
  # Rotate towards moves at half the speed of rotate away from. The reason being that if we are moving away from a direction we are probably avoiding a collision, and it looks better
  
  rotate_towards: (target_direction, weight=1.0) ->
    difference = angle_difference(@direction, target_direction)
    if difference > @rotation_speed
      @direction += @rotation_speed * weight
    if difference < -@rotation_speed
      @direction -= @rotation_speed * weight
  
  rotate_away_from: (target_direction, weight) ->
    difference = angle_difference(@direction, target_direction)
    if difference > @rotation_speed
      @direction -= @rotation_speed * weight
    if difference < -@rotation_speed
      @direction += @rotation_speed * weight
  
  direction_degrees: () ->
    Math.floor(@direction * 57.2957795)