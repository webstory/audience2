var drawGraph = function(target, links, width, height) {
  var nodes = {};
  var degree_mid = 300,
      degree_high = 1000,
      degree_max = 0;

  // Compute the distinct nodes from the links.
  links.forEach(function(link) {
    link.source = nodes[link.source] || (nodes[link.source] = {name: link.source});
    link.target = nodes[link.target] || (nodes[link.target] = {name: link.target});

    degree_max = Math.max(degree_max, link.degree);
  });

  degree_mid = degree_max * 0.03;
  degree_high = degree_max * 0.7;

  //var width = 800,
  //    height = 800;

  var force = d3.layout.force()
      .nodes(d3.values(nodes))
      .links(links)
      .size([width, height])
      .linkDistance(300)
      .charge(-1000)
      .friction(0.1)
      .on("tick", tick)
      .start();

  var svg = d3.select(target)
      .attr("width", width)
      .attr("height", height);

  svg.selectAll("*").remove();

  // Per-type markers, as they don't inherit styles.
  svg.append("defs").selectAll("marker")
      .data(["default", "arrow"])
    .enter().append("marker")
      .attr("id", function(d) { return d; })
      .attr("viewBox", "0 -5 10 10")
      .attr("refX", 15)
      .attr("refY", -1.5)
      .attr("markerWidth", 6)
      .attr("markerHeight", 6)
      .attr("orient", "auto")
    .append("path")
      .attr("d", "M0,-5L10,0L0,5");

  var degree = function(d) {
    if(d === undefined || d <= 0) return "none";
    if(d < degree_mid) return "low";
    if(d < degree_high) return "mid";
    if(d > degree_high) return "high";
  }

  var path = svg.append("g").selectAll("path")
      .data(force.links())
    .enter().append("path")
      .attr("class", function(d) { return "link " + d.type + " " + degree(d.degree); })
      .attr("marker-end", function(d) { return "url(#" + (d.type || "default") + ")"; });

  var circle = svg.append("g").selectAll("circle")
      .data(force.nodes())
    .enter().append("circle")
      .attr("r", 6)
      .call(force.drag)
      .on("mouseover", fade(0.1))
      .on("mouseout", fade(1));

  var text = svg.append("g").selectAll("text")
      .data(force.nodes())
    .enter().append("text")
      .attr("x", 8)
      .attr("y", ".31em")
      .text(function(d) { return d.name; });

  var link_label = svg.append("g").selectAll("text")
      .data(force.links())
    .enter().append("text")
      .text(function(d) { return d.degree || "0"; })
      .attr("class", function(d) { return "link-label " + degree(d.degree); })
      .attr("text-anchor", "middle");

  var linkedByIndex = {};
    links.forEach(function(d) {
        linkedByIndex[d.source.index + "," + d.target.index] = 1;
    });

  svg.selectAll("*.none").remove();

  function isConnected(a, b) {
        return linkedByIndex[a.index + "," + b.index] || linkedByIndex[b.index + "," + a.index] || a.index == b.index;
    }

  function fade(opacity) {
      return function(d) {
          circle.style("stroke-opacity", function(o) {
              thisOpacity = isConnected(d, o) ? 1 : opacity;
              this.setAttribute('fill-opacity', thisOpacity);
              return thisOpacity;
          });

          path.style("opacity", function(o) {
              return o.source === d ? 1 : opacity;
          });

          text.style("opacity", function(o) {
              thisOpacity = isConnected(d, o) ? 1 : opacity;
              this.setAttribute('opacity', thisOpacity);
              return thisOpacity;
          });

          link_label.style("opacity", function(o) {
              return o.source === d ? 1 : opacity;
          });
      };
  }

  // Use elliptical arc path segments to doubly-encode directionality.
  function tick() {
    path.attr("d", linkArc);
    circle.attr("transform", transform);
    text.attr("transform", transform);
    link_label.attr("transform", function(d) {
        var dx = (nodes[d.target.name].x - nodes[d.source.name].x),
            dy = (nodes[d.target.name].y - nodes[d.source.name].y);

        // For Self-edge
        if(dx == 0) dx = 30;
        if(dy == 0) dy = -30;

        var dr = Math.sqrt(dx * dx + dy * dy);
        var offset = (1 - (1 / dr)) / 2;
        var deg = 180 / Math.PI * Math.atan2(dy, dx);
        var x = (nodes[d.source.name].x + dx * offset);
        var y = (nodes[d.source.name].y + dy * offset);
        return "translate(" + x + ", " + y + ") rotate(" + deg + ")";
      });
  }

  function linkArc(d) {
    var x1 = d.source.x,
        y1 = d.source.y,
        x2 = d.target.x,
        y2 = d.target.y,

        dx = x2 - x1,
        dy = y2 - y1,

        dr = Math.sqrt(dx * dx + dy * dy),

        drx = dr,
        dry = dr,

        xRotation = 0, // degrees,
        largeArc = 0,  // -1 or 0,
        sweep = 1     // 1 or 0,

        // Self edge
        if( x1 == x2 && y1 == y2 ) {
          xRotation = -45;
          largeArc = 1;
          //sweep = 0

          // Make drx and dry different to get an ellipse instead of a circle
          drx = 20;
          dry = 20;

          // For whatever reason the arc collapses to a point if the beginning
          // and ending points of the arc are the same, so kludge it.
          x2 = x2 + 1;
          y2 = y2 + 1;
        }

    return "M" + x1 + "," + y1 + "A" + drx + "," + dry + " " + xRotation + "," + largeArc + "," + sweep + " " + x2 + "," + y2;
  }

  function transform(d) {
    return "translate(" + d.x + "," + d.y + ")";
  }
}