class @AngleBug
  constructor: (@canvas, @textbox, options={}) ->
    @number         = options.number || 1
    @width          = options.width  || @canvas.width
    @height         = options.height || @canvas.height
    @mid_point      = { "x": @width / 2.0, "y": @height / 2.0 }
    @new_algorithm  = options.new_algorithm || false
    
    @initialised = false
    @started = false
    @init()
  
  init: () ->
    @context = @canvas.getContext "2d"
    @boids   = (new Boid(n, { x: @mid_point.x, y: @mid_point.y, new_algorithm: @new_algorithm }) for n in [0...@number])
    @draw()
    @initialised = true
    
  start: () ->
    if @started
      return false
    
    @started = true  
    
    unless @initialised
      @init()
    
    @target = -3
    
    frame = () =>
      boid = @boids[0]
      # If the boid has reached its target direction (or close enough) then set a new target for the boid.
      if @target - 0.05 < boid.direction < @target + 0.05
        @target = Math.floor(((Math.PI * 0.5) + Math.random()) * 100) / 100
        if boid.direction > 0
          @target *= -1
      boid.rotate_towards(@target, 0.5)
      # Draw the boid
      @draw()
    
    @intervalId = setInterval(frame, 30)
  
  stop: () ->
    clearInterval @intervalId
    @started = false

  reset: () ->
    @stop()
    @init()

  draw: () ->
    @context.clearRect(0,0,@width,@height)
    angle = @boids[0].direction
    @draw_circle(@context, @mid_point.x, @mid_point.y, angle, "#DCC")
    @textbox.innerHTML = "#{sign(direction_degrees(@boids[0].direction))}&deg;<br />#{sign(Math.floor(@boids[0].direction * 100) / 100)} rad<br />Rotating to #{sign(@target)} rad"
    _.each(@boids, (b) => b.draw(@context))

  draw_circle: (context, x, y, angle, colour) ->
    context.beginPath()
    anticlockwise = (angle < 0)
    context.arc(
      x,
      y,
      65,
      0,
      angle,
      anticlockwise
    )
    context.lineWidth = 10
    context.lineCap = "butt"
    context.strokeStyle = colour
    context.stroke()
    context.closePath()

sign = (number) ->
  pos_sign = "+" if (number > 0)
  pos_sign ?= ""
  "#{pos_sign}#{number}"

direction_degrees = (radian) ->
  Math.floor(radian * 57.2957795)

angle_difference = (start, end) ->
  diff = (end - start) # % (Math.PI * 2) # The difference, and if it's over or under PI, modulus it
  diff -= Math.PI * 2 if diff > Math.PI
  diff += Math.PI * 2 if diff < -Math.PI
  diff
  
# The boid itself

class Boid
  constructor: (@id, options={}) ->
    @x = options.x
    @y = options.y
    @direction = 3
    @speed = 0
    @rotation_speed = 0.075
    @use_new = options.new_algorithm || false
  
  draw: (context) ->
    context.save()
    # Move to the appropriate location
    context.translate(@x, @y)
    context.fillStyle = "black"
    context.strokeStyle = "black"
    # Rotate to the appropriate direction
    context.rotate(@direction)
    # Draw the arrow shape
    context.beginPath()
    context.moveTo(57, 0)
    context.lineTo(-43, 37)
    context.lineTo(-23, 0)
    context.lineTo(-43, -37)
    context.closePath()
    context.fill()
    context.restore()
    
  rotate_towards: (direction, weight=1.0) ->
    if @use_new
      @new_rotate_towards(direction, weight)
    else
      @old_rotate_towards(direction, weight)
    
  old_rotate_towards: (direction, weight=1.0) ->
    if direction > @direction
      @direction += (@rotation_speed * weight)
    else if direction < @direction
      @direction -= (@rotation_speed * weight)
  
  new_rotate_towards: (target_direction, weight=1.0) ->
    difference = angle_difference(@direction, target_direction)
    if difference > 0
      @direction += @rotation_speed * weight
    if difference < 0
      @direction -= @rotation_speed * weight
    
    if @direction > Math.PI
      @direction = @direction - Math.PI * 2
    
    if @direction < -Math.PI
      @direction = @direction - Math.PI * -2