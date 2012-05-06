(function() {
  var Boid, root;
  root = this;
  root.width = 530;
  root.height = 430;
  root.start = function() {
    var boids, canvas, context, frame;
    canvas = document.getElementById("boids");
    context = canvas.getContext("2d");
    boids = [new Boid];
    frame = function() {
      root.draw(context, boids);
      return _.each(boids, function(b) {
        return b.move(boids);
      });
    };
    return this.intervalId = setInterval(frame, 20);
  };
  root.stop = function() {
    return clearInterval(this.intervalId);
  };
  root.draw = function(context, boids) {
    context.clearRect(0, 0, root.width, root.height);
    return _.each(boids, function(b) {
      return b.draw(context);
    });
  };
  Boid = (function() {
    function Boid() {
      this.x = 0;
      this.y = 0;
      this.direction = 0;
    }
    Boid.prototype.draw = function(context) {
      context.beginPath();
      context.arc(this.x, this.y, 10, 0, Math.PI * 2, true);
      context.closePath();
      return context.fill();
    };
    Boid.prototype.move = function(boids) {
      this.x += 3;
      this.y += 3;
      if (this.x > root.width + 20) {
        this.x = -20;
      }
      if (this.y > root.height + 20) {
        return this.y = -20;
      }
    };
    return Boid;
  })();
}).call(this);
