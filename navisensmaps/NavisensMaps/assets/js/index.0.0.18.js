// TODO ? double tap does not work
// TODO local mode should turn off gps
























const NAVISENS_URL = 'https://www.navisens.com';
const NAVISENS_ORANGE = '#dd4958';
const NAVISENS_TRIADL = '#4857dd';
const NAVISENS_TRIADR = '#57dd48';

const SIZE = 10;
const MARGIN = 10;

const RADIUS = 5;
const INNER = 0.5;
const MOTIONS = [240, 0, 120];
const ICONSIZE = 200;
const MIN_OFFSET = Math.PI / 3;
const SMOOTH_COLORS = 1 / 5; // inverse of number of samples to smooth

const MAX_SAMPLES = 100;
const MIN_DISTANCE = 1e-7; // precision of floats passed in from Java

const DEFAULT_LOCATION = [51.4778, 0.0015];

var overflowed = false;
var loadedInterface = false;

function SET(key, item, compress) {
  var value = JSON.stringify(item);
  if (compress)
    value = LZString.compress(value);
  // DEPLOY
  // console.log('setting ' + key + ' to ' + value);
  try {
    localStorage.setItem(key, value);
    overflowed = false;
  } catch(e) {
    overflowed = true;
  }
}

function GET(key, compress) {
  var value = localStorage.getItem(key);
  if (compress)
    value = LZString.decompress(value);
  return JSON.parse(value);
}

function START() {
  SET('NAVISENS_JAVASCRIPT_INITIALIZATION_COMPLETE', true);
  
  SET('coords', DEFAULT_LOCATION);
  SET('zoom', 19);
  
  SET('shouldPan', true);
  SET('usercoords', DEFAULT_LOCATION);
  
  SET('points', 1);
  SET('point.0', [], true);
}

function SAVE() {
  SET('coords', map.getCenter());
  SET('zoom', map.getZoom());
  SET('usercoords', users[userID][0].getLatLng());
  var points = GET('points') - 1;
  
  if (recentPoints.point) {
    var point = {'p': recentPoints.point, 'd': []};
    for (var i = 0, l = MOTIONS.length; i < l; i++)
      if (recentPoints.markers[i])
        point.d.push({'c': recentPoints.markers[i].category, 'w': recentPoints.markers[i].weight});
    allPoints.push(point)
    
    SET('point.' + points, allPoints, true);
    allPoints.splice(-1); // remove extra metadata added for saving only
  } else {
    SET('point.' + points, allPoints, true);
  }
  
  // console.log("SAVED: " + GET('NAVISENS_JAVASCRIPT_INITIALIZATION_COMPLETE'));
}

function STOP() {
  if (map)
    map.remove();
  localStorage.removeItem('NAVISENS_JAVASCRIPT_INITIALIZATION_COMPLETE');
  localStorage.removeItem('coords');
  localStorage.removeItem('zoom');
  localStorage.removeItem('shouldPan');
  localStorage.removeItem('usercoords');
  for (var i = 0, l = GET('points'); i < l; i++) {
    localStorage.removeItem('point.' + i);
  }
  localStorage.removeItem('points');
  
  console.log("STOPPED");
}

if (GET('NAVISENS_JAVASCRIPT_INITIALIZATION_COMPLETE') == null)
START();

var deviceScaling = window.devicePixelRatio;
var colors = ['#ff4b00', '#bac900', '#EC1813', '#55BCBE', '#D2204C', '#FF0000', '#ada59a', '#3e647e'],
pi2 = Math.PI * 2;

// ===== INTERFACE =====

var debug = false;

var simpleMode = false;
var clusterMode = true;

var map = null;
// var user = null;
var polyline = null;
var allPoints = null;
var recentPoint = null;
var recentPoints = null;

var users = {};
var userID = '';

var currentColor = 0;

L.Icon.MarkerUser = L.Icon.extend({
                                  options: {
                                  iconSize: new L.Point(8 * RADIUS, 8 * RADIUS),
                                  className: 'leaflet-markercluster-icon'
                                  },
                                  
                                  createIcon: function () {
                                  // based on L.Icon.Canvas from shramov/leaflet-plugins (BSD licence)
                                  var e = document.createElement('canvas');
                                  this._setIconStyles(e, 'icon');
                                  var s = this.options.iconSize;
                                  e.width = deviceScaling * s.x;
                                  e.height = deviceScaling * s.y;
                                  this.draw(e.getContext('2d'), e.width, e.height);
                                  return e;
                                  },
                                  
                                  createShadow: function () {
                                  return null;
                                  },
                                  
                                  draw: function(canvas, width, height) {
                                  if (!customizingRotation) {
                                  canvas.beginPath();
                                  canvas.lineWidth = deviceScaling;
                                  canvas.strokeStyle = 'hsl(' + MOTIONS[this.category] + ', 100%, 50%)';
                                  canvas.fillStyle = 'hsl(' + currentColor + ', 100%, 50%)';
                                  canvas.translate(deviceScaling * 4 * RADIUS, deviceScaling * 4 * RADIUS);
                                  canvas.rotate(this.heading * Math.PI / 180);
                                  canvas.moveTo(deviceScaling * 1.5 * RADIUS, deviceScaling * -2 * RADIUS);
                                  canvas.lineTo(0, deviceScaling * -4 * RADIUS);
                                  canvas.lineTo(deviceScaling * -1.5 * RADIUS, deviceScaling * -2 * RADIUS);
                                  canvas.arcTo(0, deviceScaling * -3 * RADIUS, deviceScaling * 1.5 * RADIUS, deviceScaling * -2 * RADIUS, deviceScaling * 2.5 * RADIUS)
                                  canvas.closePath();
                                  canvas.fill();
                                  canvas.stroke();
                                  canvas.setTransform(1, 0, 0, 1, 0, 0);
                                  }
                                  
                                  if (navisens)
                                  canvas.drawImage(navisens, deviceScaling * RADIUS, deviceScaling * RADIUS, deviceScaling * 6 * RADIUS, deviceScaling * 6 * RADIUS);
                                  }
                                  });

L.Icon.MarkerOtherUser = L.Icon.extend({
                                       options: {
                                       iconSize: new L.Point(5 * RADIUS, 5 * RADIUS),
                                       className: 'leaflet-markercluster-icon'
                                       },
                                       
                                       createIcon: function () {
                                       // based on L.Icon.Canvas from shramov/leaflet-plugins (BSD licence)
                                       var e = document.createElement('canvas');
                                       this._setIconStyles(e, 'icon');
                                       var s = this.options.iconSize;
                                       e.width = deviceScaling * s.x;
                                       e.height = deviceScaling * s.y;
                                       this.draw(e.getContext('2d'), e.width, e.height);
                                       return e;
                                       },
                                       
                                       createShadow: function () {
                                       return null;
                                       },
                                       
                                       draw: function(canvas, width, height) {
                                       if (navisens) {
                                       canvas.drawImage(navisens, deviceScaling * 0.5 * RADIUS, deviceScaling * 0.5 * RADIUS, deviceScaling * 4 * RADIUS, deviceScaling * 4 * RADIUS);
                                       if (this.hex) {
                                       canvas.globalCompositeOperation = 'source-in';
                                       canvas.fillStyle = this.hex;
                                       canvas.fillRect(deviceScaling * 0.5 * RADIUS, deviceScaling * 0.5 * RADIUS, deviceScaling * 4 * RADIUS, deviceScaling * 4 * RADIUS);
                                       canvas.globalCompositeOperation = 'source-over';
                                       }
                                       }
                                       
                                       if (!customizingRotation) {
                                       canvas.beginPath();
                                       canvas.fillStyle = 'hsl(' + MOTIONS[this.category] + ', 100%, 50%)';
                                       canvas.translate(deviceScaling * 2.5 * RADIUS, deviceScaling * 2.5 * RADIUS);
                                       canvas.rotate(this.heading * Math.PI / 180);
                                       canvas.moveTo(deviceScaling * 1 * RADIUS, deviceScaling * -1.25 * RADIUS);
                                       canvas.lineTo(0, deviceScaling * -2.5 * RADIUS);
                                       canvas.lineTo(deviceScaling * -1 * RADIUS, deviceScaling * -1.25 * RADIUS);
                                       canvas.arcTo(0, deviceScaling * -1.75 * RADIUS, deviceScaling * 1 * RADIUS, deviceScaling * -1.25 * RADIUS, deviceScaling * 1.75 * RADIUS)
                                       canvas.closePath();
                                       canvas.fill();
                                       canvas.setTransform(1, 0, 0, 1, 0, 0);
                                       }
                                       }
                                       });

L.Icon.MarkerCustomRotation = L.Icon.extend({
                                            options: {
                                            iconSize: new L.Point(32 * RADIUS, 32 * RADIUS),
                                            className: 'leaflet-markercluster-icon'
                                            },
                                            
                                            createIcon: function () {
                                            // based on L.Icon.Canvas from shramov/leaflet-plugins (BSD licence)
                                            var e = document.createElement('canvas');
                                            this._setIconStyles(e, 'icon');
                                            var s = this.options.iconSize;
                                            e.width = deviceScaling * s.x;
                                            e.height = deviceScaling * s.y;
                                            this.draw(e.getContext('2d'), e.width, e.height);
                                            return e;
                                            },
                                            
                                            createShadow: function () {
                                            return null;
                                            },
                                            
                                            draw: function(canvas, width, height) {
                                            canvas.translate(deviceScaling * 16 * RADIUS, deviceScaling * 16 * RADIUS);
                                            
                                            canvas.fillStyle = '#000';
                                            canvas.textAlign = 'center';
                                            canvas.textBaseline = 'middle';
                                            canvas.font = '' + (deviceScaling * 10) + 'px sans-serif';
                                            canvas.fillText('N', 0, deviceScaling * -5 * RADIUS);
                                            
                                            canvas.font = 'bold ' + (deviceScaling * 7) + 'px sans-serif';
                                            canvas.fillText('S', 0, deviceScaling * 5 * RADIUS);
                                            canvas.fillText('E', deviceScaling * 5 * RADIUS, 0);
                                            canvas.fillText('W', deviceScaling * -5 * RADIUS, 0);
                                            
                                            canvas.rotate((this.heading + (customRotationHandle && customRotationHandle.headingOffset || 0)) * Math.PI / 180);
                                            
                                            canvas.beginPath();
                                            canvas.fillStyle = 'rgba(127, 127, 127, 0.25)';
                                            canvas.arc(0, 0, deviceScaling * 15.5 * RADIUS, -Math.PI / 2 - Math.PI / 40, 3 * Math.PI / 2 - Math.PI / 40);
                                            canvas.fill();
                                            canvas.lineWidth = deviceScaling * 1;
                                            canvas.setLineDash([deviceScaling * 31 * Math.PI / 10, deviceScaling * 31 * Math.PI / 10]);
                                            canvas.strokeStyle = 'rgba(0, 0, 0, 0.5)';
                                            canvas.stroke();
                                            canvas.closePath();
                                            
                                            canvas.beginPath();
                                            canvas.fillStyle = '#555';
                                            canvas.moveTo(0, 0);
                                            canvas.lineTo(deviceScaling * 2 * RADIUS, deviceScaling * 3 * RADIUS);
                                            canvas.lineTo(0, deviceScaling * -4 * RADIUS);
                                            canvas.lineTo(deviceScaling * -2 * RADIUS, deviceScaling * 3 * RADIUS);
                                            canvas.closePath();
                                            canvas.fill();
                                            
                                            canvas.beginPath();
                                            canvas.lineWidth = deviceScaling * 2;
                                            canvas.strokeStyle = '#111';
                                            canvas.setLineDash([deviceScaling * 8 * Math.PI / 10, deviceScaling * 8 * Math.PI / 10]);
                                            canvas.arc(0, 0, deviceScaling * 4 * RADIUS, -Math.PI / 2 - Math.PI / 40, 3 * Math.PI / 2 - Math.PI / 40);
                                            canvas.stroke();
                                            canvas.closePath();
                                            
                                            canvas.setLineDash([]);
                                            
                                            canvas.setTransform(1, 0, 0, 1, 0, 0);
                                            }
                                            });

L.Icon.MarkerCustomRotationHandle = L.Icon.extend({
                                                  options: {
                                                  iconSize: new L.Point(32 * RADIUS, 32 * RADIUS),
                                                  className: 'leaflet-markercluster-icon'
                                                  },
                                                  
                                                  createIcon: function () {
                                                  // based on L.Icon.Canvas from shramov/leaflet-plugins (BSD licence)
                                                  var e = document.createElement('canvas');
                                                  this._setIconStyles(e, 'icon');
                                                  var s = this.options.iconSize;
                                                  e.width = deviceScaling * s.x;
                                                  e.height = deviceScaling * s.y;
                                                  return e;
                                                  },
                                                  
                                                  createShadow: function () {
                                                  return null;
                                                  },
                                                  
                                                  draw: function(canvas, width, height) {
                                                  return null;
                                                  }
                                                  });

var touching = false;
var touchstart = null; // L.point containerPoint
var dragging = false;

var navisens = L.DomUtil.create('img');
navisens.src = 'navisens.svg';

// var userIcon = null; // L.icon({ iconUrl: 'navisens.svg' }); // new L.Icon.MarkerUser();

var customLocation = null;
var customRotation = null;
var customRotationIcon = null;
var customHeading = null;
var customHeadingVector = null;
var customRotationHandle = null;

var customizingLocation = false;
var customizingRotation = false;

// var popup = L.popup();

function lookAtRotation() {
  var vec = map.latLngToContainerPoint(customHeading.getLatLng()).subtract(map.latLngToContainerPoint(users[userID][0].getLatLng()));
  customRotationIcon.heading = Math.atan2(vec.y, vec.x) * 180 / Math.PI + 90;
  customRotation.setIcon(customRotationIcon);
  
  customHeadingVector.setLatLngs([users[userID][0].getLatLng(), customHeading.getLatLng()]);
}

function recalculateRotation(e) {
  var vec = map.latLngToContainerPoint(e.latlng).subtract(map.latLngToContainerPoint(users[userID][0].getLatLng()));
  customRotationIcon.heading = Math.atan2(vec.y, vec.x) * 180 / Math.PI + 90;
  customRotation.setIcon(customRotationIcon);
  
  customHeading.setLatLng(e.latlng);
  customHeading.addTo(map);
  customHeadingVector.setLatLngs([users[userID][0].getLatLng(), e.latlng]);
}

function handleCustomRotation(e) {
  if (!customRotationHandle.offset) {
    var rotPoint = map.latLngToContainerPoint(customRotation.getLatLng());
    if (map.latLngToContainerPoint(customRotationHandle.getLatLng()).distanceTo(rotPoint) <= 3)
      return;
    if (!touchstart) return;
    customRotationHandle.offset = touchstart.subtract(rotPoint);
    customRotationHandle.startAngle = Math.atan2(customRotationHandle.offset.y, customRotationHandle.offset.x) * 180 / Math.PI;
    customHeading.removeFrom(map);
  }
  
  var pos = map.latLngToContainerPoint(customRotationHandle.getLatLng()).add(customRotationHandle.offset);
  var vec = pos.subtract(map.latLngToContainerPoint(customRotation.getLatLng()));
  customRotationHandle.headingOffset = Math.atan2(vec.y, vec.x) * 180 / Math.PI - customRotationHandle.startAngle;
  
  customHeadingVector.setLatLngs([users[userID][0].getLatLng(), users[userID][0].getLatLng()]);
  customRotation.setIcon(customRotationIcon);
}

function recalculateCustomRotation() {
  customRotationIcon.heading += customRotationHandle.headingOffset;
  customRotationHandle.headingOffset = 0;
  customRotationHandle.setLatLng(users[userID][0].getLatLng());
  customRotationHandle.offset = null;
}

function onMapClick(e) {
  if (customizingLocation) {
    if (customLocation != null) {
      customLocation.setLatLng(e.latlng);
    }
    return;
  }
  if (customizingRotation) {
    // if (customHeading != null) {
    //     customHeading.setLatLng(e.latlng);
    recalculateRotation(e);
    // }
    return;
  }
  /*
   if (shouldPan) {
   popup.setLatLng(e.latlng)
   .setContent(e.latlng.toString())
   .openOn(map);
   shouldPan = false;
   } else {
   map.closePopup(popup);
   shouldPan = true;
   }
   */
}

function onMapLongClick(e) {
  if (e.originalEvent.button == 2) {
    onClickLocation(toggle);
    if (customLocation != null) {
      customLocation.setLatLng(e.latlng);
      map.panTo(e.latlng);
    }
  }
}

// ===== DRAWING =====

var volatileLocation = null;
var volatileDistance = Math.min();
var volatileSamples = 0;

var pruneCluster = new PruneClusterForLeaflet(SIZE, MARGIN);

pruneCluster.BuildLeafletCluster = function (cluster, position) {
  var m = new L.Marker(position, {
                       icon: this.BuildLeafletClusterIcon(cluster)
                       });
  m.expanded = false;
  m._leafletClusterBounds = cluster.bounds;
  m.on('click', function () {
       toggleShouldPan(false);
       var cbounds = m._leafletClusterBounds;
       var markersArea = pruneCluster.Cluster.FindMarkersInArea(cbounds);
       var b = pruneCluster.Cluster.ComputeBounds(markersArea);
       if (b) {
       var bounds = new L.LatLngBounds(new L.LatLng(b.minLat, b.maxLng), new L.LatLng(b.maxLat, b.minLng));
       var zoomLevelBefore = pruneCluster._map.getZoom(), zoomLevelAfter = pruneCluster._map.getBoundsZoom(bounds, false, new L.Point(20, 20));
       if (zoomLevelAfter === zoomLevelBefore) {
       if (!loadedInterface || m.expanded) {
       m.expanded = false;
       m.setIcon(pruneCluster.BuildLeafletClusterIcon(cluster));
       m.setZIndexOffset(0);
       } else {
       m.expanded = true;
       m.setIcon(pruneCluster.BuildLeafletClusterIconDetailed(cluster));
       m.setZIndexOffset(100);
       }
       pruneCluster._map.setView(m.getLatLng(), zoomLevelAfter);
       }
       else {
       pruneCluster._map.fitBounds(bounds);
       }
       }
       });
  return m;
}

pruneCluster.PrepareLeafletMarker = function (marker, data, category) {
  var e = new L.Icon.MarkerSingle();
  
  e.category = category;
  
  marker.setIcon(e);
};

pruneCluster.BuildLeafletClusterIcon = function(cluster) {
  var e = new L.Icon.MarkerCluster();
  
  e.stats = cluster.stats;
  e.totalWeight = cluster.totalWeight;
  return e;
};

pruneCluster.BuildLeafletClusterIconDetailed = function(cluster) {
  var e = new L.Icon.MarkerClusterDetailed();
  
  e.stats = cluster.stats;
  e.totalWeight = cluster.totalWeight;
  return e;
};

L.Icon.MarkerSingle = L.Icon.extend({
                                    options: {
                                    iconSize: new L.Point(RADIUS, RADIUS),
                                    className: 'leaflet-markercluster-icon'
                                    },
                                    
                                    createIcon: function () {
                                    // based on L.Icon.Canvas from shramov/leaflet-plugins (BSD licence)
                                    var e = document.createElement('canvas');
                                    this._setIconStyles(e, 'icon');
                                    var s = this.options.iconSize;
                                    e.width = deviceScaling * s.x;
                                    e.height = deviceScaling * s.y;
                                    this.draw(e.getContext('2d'), e.width, e.height);
                                    return e;
                                    },
                                    
                                    createShadow: function () {
                                    return null;
                                    },
                                    
                                    draw: function(canvas, width, height) {
                                    canvas.beginPath();
                                    canvas.fillStyle = 'hsl(' + MOTIONS[this.category] + ', 100%, 50%)';
                                    canvas.arc(deviceScaling * RADIUS / 2, deviceScaling * RADIUS / 2, deviceScaling * 0.75 * RADIUS / 2, 0, Math.PI*2);
                                    canvas.fill();
                                    canvas.closePath();
                                    }
                                    });

L.Icon.MarkerCluster = L.Icon.extend({
                                     options: {
                                     iconSize: new L.Point(RADIUS, RADIUS),
                                     className: 'prunecluster leaflet-markercluster-icon'
                                     },
                                     
                                     createIcon: function () {
                                     // based on L.Icon.Canvas from shramov/leaflet-plugins (BSD licence)
                                     var e = document.createElement('canvas');
                                     this._setIconStyles(e, 'icon');
                                     var s = this.options.iconSize;
                                     e.width = deviceScaling * s.x;
                                     e.height = deviceScaling * s.y;
                                     this.draw(e.getContext('2d'), e.width, e.height);
                                     return e;
                                     },
                                     
                                     createShadow: function () {
                                     return null;
                                     },
                                     
                                     draw: function(canvas, width, height) {
                                     canvas.beginPath();
                                     
                                     var hue = 0;
                                     var red = 0;
                                     for (var i = 0, l = MOTIONS.length; i < l; ++i) {
                                     var size = this.stats[i] / this.totalWeight;
                                     if (MOTIONS[i] == 0) {
                                     red = size;
                                     continue;
                                     }
                                     
                                     hue += size * MOTIONS[i];
                                     }
                                     if (hue > (1 - red) * 180) {
                                     hue += red * 360
                                     }
                                     
                                     canvas.fillStyle = 'hsl(' + hue + ', 100%, 50%)';
                                     // canvas.filter = 'blur(' + (deviceScaling / 2) + 'px)';
                                     canvas.arc(deviceScaling * RADIUS / 2, deviceScaling * RADIUS / 2, deviceScaling * RADIUS / 2, 0, Math.PI*2);
                                     canvas.fill();
                                     canvas.closePath();
                                     }
                                     });

L.Icon.MarkerClusterDetailed = L.Icon.extend({
                                             options: {
                                             iconSize: new L.Point(10 * RADIUS, 10 * RADIUS),
                                             className: 'prunecluster leaflet-markercluster-icon'
                                             },
                                             
                                             createIcon: function () {
                                             // based on L.Icon.Canvas from shramov/leaflet-plugins (BSD licence)
                                             var e = document.createElement('canvas');
                                             this._setIconStyles(e, 'icon');
                                             var s = this.options.iconSize;
                                             e.width = deviceScaling * s.x;
                                             e.height = deviceScaling * s.y;
                                             this.draw(e.getContext('2d'), e.width, e.height);
                                             return e;
                                             },
                                             
                                             createShadow: function () {
                                             return null;
                                             },
                                             
                                             draw: function(canvas, width, height) {
                                             var lol = 0;
                                             
                                             var start = -Math.PI / 2;
                                             var angles = [];
                                             for (var i = 0, l = MOTIONS.length; i < l; ++i) {
                                             var size = this.stats[i] / this.totalWeight;
                                             
                                             if (size > 0) {
                                             canvas.beginPath();
                                             canvas.moveTo(deviceScaling * 5 * RADIUS, deviceScaling * 5 * RADIUS);
                                             canvas.fillStyle = 'hsl(' + MOTIONS[i] + ', 100%, 50%)';
                                             var from = start,
                                             to = start + size * pi2;
                                             
                                             if (to < from) {
                                             from = start;
                                             }
                                             
                                             angles.push((from + to) / 2);
                                             
                                             canvas.arc(deviceScaling * 5 * RADIUS, deviceScaling * 5 * RADIUS, deviceScaling * 4 * RADIUS, from, to);
                                             
                                             start = to;
                                             canvas.lineTo(deviceScaling * 5 * RADIUS, deviceScaling * 5 * RADIUS);
                                             canvas.fill();
                                             canvas.closePath();
                                             }
                                             }
                                             
                                             canvas.beginPath();
                                             canvas.fillStyle = 'white';
                                             canvas.arc(deviceScaling * 5 * RADIUS, deviceScaling * 5 * RADIUS, deviceScaling * INNER * 4 * RADIUS, 0, Math.PI*2);
                                             canvas.fill();
                                             canvas.closePath();
                                             
                                             canvas.fillStyle = '#111';
                                             canvas.textAlign = 'center';
                                             canvas.textBaseline = 'middle';
                                             canvas.font = 'bold ' + (deviceScaling * 8) + 'px sans-serif';
                                             canvas.fillText(this.totalWeight, deviceScaling * 5 * RADIUS, deviceScaling * 5 * RADIUS, deviceScaling * INNER * 8 * RADIUS);
                                             
                                             canvas.strokeStyle = 'rgba(0, 0, 0, 0.5)';
                                             canvas.lineWidth = 2;
                                             canvas.fillStyle = 'white';
                                             canvas.font = '' + (deviceScaling * 7) + 'px sans-serif';
                                             
                                             for (var i = 0, l = angles.length; i < l; ++i) {
                                             var alpha = angles[i];
                                             var j = (i + 1) % l;
                                             var alpha2 = angles[j];
                                             var diff1 = L.Util.wrapNum((alpha - alpha2), [0, pi2]);
                                             var diff2 = L.Util.wrapNum((alpha2 - alpha), [0, pi2]);
                                             if (diff1 < diff2) {
                                             if (diff1 < MIN_OFFSET) {
                                             var offset = (MIN_OFFSET - diff1) / 2;
                                             angles[i] += offset;
                                             angles[j] -= offset;
                                             }
                                             } else {
                                             if (diff2 < MIN_OFFSET) {
                                             var offset = (MIN_OFFSET - diff2) / 2;
                                             angles[i] -= offset;
                                             angles[j] += offset;
                                             }
                                             }
                                             }
                                             
                                             for (var i = 0, j = 0, l = MOTIONS.length; i < l; ++i) {
                                             var size = this.stats[i] / this.totalWeight;
                                             
                                             if (size > 0) {
                                             var alpha = angles[j];
                                             j++;
                                             var x = Math.cos(alpha);
                                             var y = Math.sin(alpha);
                                             
                                             canvas.strokeText((+(Math.round((100 * size) + "e+1") + "e-1") + "%"),
                                                               deviceScaling * 5 * RADIUS + deviceScaling * INNER * 6 * RADIUS * x,
                                                               deviceScaling * 5 * RADIUS + deviceScaling * INNER * 6 * RADIUS * y);
                                             canvas.fillText((+(Math.round((100 * size) + "e+1") + "e-1") + "%"),
                                                             deviceScaling * 5 * RADIUS + deviceScaling * INNER * 6 * RADIUS * x,
                                                             deviceScaling * 5 * RADIUS + deviceScaling * INNER * 6 * RADIUS * y);
                                             }
                                             }
                                             }
                                             });

L.Icon.MarkerBeacon = L.Icon.extend({
                                    options: {
                                    iconSize: new L.Point(7 * RADIUS, 7 * RADIUS),
                                    className: 'leaflet-markercluster-icon'
                                    },
                                    
                                    createIcon: function () {
                                    // based on L.Icon.Canvas from shramov/leaflet-plugins (BSD licence)
                                    var e = document.createElement('canvas');
                                    this._setIconStyles(e, 'icon');
                                    var s = this.options.iconSize;
                                    e.width = deviceScaling * s.x;
                                    e.height = deviceScaling * s.y;
                                    this.draw(e.getContext('2d'), e.width, e.height);
                                    return e;
                                    },
                                    
                                    createShadow: function () {
                                    return null;
                                    },
                                    
                                    draw: function(canvas, width, height) {
                                    canvas.strokeStyle = NAVISENS_TRIADL;
                                    canvas.fillStyle = NAVISENS_TRIADL;
                                    
                                    canvas.beginPath();
                                    canvas.lineWidth = 1.25 * deviceScaling;
                                    canvas.arc(3.5 * deviceScaling * RADIUS, 3.5 * deviceScaling * RADIUS, 2 * deviceScaling * RADIUS, 0, Math.PI*2);
                                    canvas.stroke();
                                    canvas.closePath();
                                    
                                    canvas.beginPath();
                                    canvas.lineWidth = 2 * deviceScaling;
                                    canvas.arc(3.5 * deviceScaling * RADIUS, 3.5 * deviceScaling * RADIUS, 1.375 * deviceScaling * RADIUS, 0, Math.PI*2);
                                    canvas.stroke();
                                    canvas.closePath();
                                    
                                    canvas.beginPath();
                                    canvas.arc(3.5 * deviceScaling * RADIUS, 3.5 * deviceScaling * RADIUS, 0.875 * deviceScaling * RADIUS, 0, Math.PI*2);
                                    canvas.fill();
                                    canvas.closePath();
                                    }
                                    });

// ===== CONTROLS =====

var message = L.control.messagebox({ position: 'bottomright'});

var center = L.easyButton({
                          states: [{
                                   stateName: 'on',
                                   icon: 'fa-stack-2x fa-crosshairs icon navisens-orange',
                                   title: 'Track user',
                                   onClick: function () {toggleShouldPan(false);}
                                   }, {
                                   stateName: 'off',
                                   icon: 'fa-stack-2x fa-crosshairs icon',
                                   title: 'Untrack user',
                                   onClick: function () {toggleShouldPan(true);}
                                   }]
                          });

function toggleShouldPan(should) {
  SET('shouldPan', should);
  if (should) {
    center.state('on');
  } else {
    center.state('off');
    if (customizingLocation && customLocation != null)
      map.panTo(customLocation.getLatLng());
  }
}

confirm = function() {};
cancel = function() {};
clean = function() {};

var yes = L.easyButton('fa-stack-2x fa-check icon', function() {yesno.remove(); confirm();});
var no = L.easyButton('fa-stack-2x fa-times icon', function() {yesno.remove(); cancel();});
var yesno = L.easyBar([yes, no]);

function onClickLocation(control) {
  cancel();
  control.state('location');
  yesno.addTo(map);
  
  customizingLocation = true;
  
  customLocation = L.marker(users[userID][0].getLatLng(), {draggable: true, keyboard: false, opacity: 0.8, zIndexOffset: 999});
  customLocation.on("dragend", function (e) {if (!GET('shouldPan')) map.panTo(e.target.getLatLng());});
  customLocation.addTo(map);
  
  toggleShouldPan(false);
  
  message.show('Tap or drag the marker to change your location. If you get lost, click the &target; to center yourself. Press the &check; to confirm, or the &cross; to cancel.', 30000);
  
  confirm = function() {
    var i = GET('points') - 1;
    SET('point.' + i, allPoints, true);
    SET('points', i + 2);
    SET('point.' + (i + 1), [], true);
    allPoints = [];
    
    polyline.setStyle({color: '#555', opacity: 0.5, weight: 0.8});
    polyline = L.polyline([], {smoothFactor: 0.8, color: '#111', opacity: 0.8, weight: 1.5}).addTo(map);
    
    recentPoints = {'point': null, 'markers': []};
    
    volatileLocation = customLocation.getLatLng();
    volatileDistance = volatileLocation.distanceTo(users[userID][0].getLatLng()) / 2;
    if (volatileDistance < MIN_DISTANCE)
      volatileDistance = MIN_DISTANCE;
    volatileSamples = 0;
    
    webkit.messageHandlers.customLocationInitialized.postMessage([customLocation.getLatLng().lat, customLocation.getLatLng().lng, users[userID][1].heading]);
    
    clean();
    
    onClickHeading(control);
  };
  
  cancel = function() {
    control.state('settings');
    clean();
  };
  
  clean = function() {
    message.hide();
    if (customizingLocation)
      customLocation.removeFrom(map);
    customizingLocation = false;
  };
}

function onClickHeading(control) {
  cancel();
  control.state('heading');
  yesno.addTo(map);
  
  customizingRotation = true;
  
  var location = (customLocation || users[userID][0]).getLatLng();
  
  customRotation = L.marker(location, {keyboard: false, icon: customRotationIcon, opacity: 0.75, zIndexOffset: 99});
  customRotationIcon.heading = users[userID][1].heading;
  customRotation.addTo(map);
  
  var headingLocation = map.latLngToContainerPoint(location);
  var offset = L.point(Math.sin(users[userID][1].heading * Math.PI / 180), -Math.cos(users[userID][1].heading * Math.PI / 180)).multiplyBy(100);
  
  customHeading = L.marker(map.containerPointToLatLng(headingLocation.add(offset)), {draggable: true, keyboard: false, opacity: 0.8, zIndexOffset: 999});
  customHeading.on("drag", lookAtRotation);
  // customHeading.addTo(map);
  
  customHeadingVector = L.polyline([users[userID][0].getLatLng(), users[userID][0].getLatLng()], {color: '#555', opacity: 0.8, weight: 1.5}).addTo(map);
  
  customRotationHandle = L.marker(location, {draggable: true, keyboard: false, icon: new L.Icon.MarkerCustomRotationHandle(), zIndexOffset: 998});
  customRotationHandle.on('drag', handleCustomRotation);
  customRotationHandle.on('dragend', recalculateCustomRotation);
  customRotationHandle.addTo(map);
  
  message.show('Drag the circle to change your heading, or tap on the map to look in a direction. Then, face your phone in the new direction. Press the &check; to confirm, or the &cross; to cancel.', 30000);
  
  confirm = function() {
    webkit.messageHandlers.customLocationInitialized.postMessage([users[userID][0].getLatLng().lat, users[userID][0].getLatLng().lng, customRotationIcon.heading]);
    clean();
  };
  
  cancel = function() {
    clean();
  };
  
  clean = function() {
    message.hide();
    control.state('settings');
    if (customizingRotation) {
      customHeading.removeFrom(map);
      customRotation.removeFrom(map);
      customHeadingVector.removeFrom(map);
      customRotationHandle.removeFrom(map);
    }
    customizingRotation = false;
  };
}

var toggle = L.easyButton({
                          states: [{
                                   stateName: 'settings',
                                   icon: 'fa-stack-2x fa-cog icon',
                                   title: 'Reinitialize',
                                   onClick: onClickLocation
                                   }, {
                                   stateName: 'location',
                                   icon: 'fa-stack-2x fa-map-marker icon navisens-orange',
                                   title: 'Set location',
                                   onClick: onClickHeading
                                   }, {
                                   stateName: 'heading',
                                   icon: 'fa-stack-2x fa-compass icon navisens-orange',
                                   title: 'Set heading',
                                   onClick: onClickLocation
                                   }]
                          });

var credits = L.controlCredits({
                               image: "./navisens.svg",
                               link: NAVISENS_URL,
                               position: 'topright',
                               text: "Location services<br/>by <b>Navisens, Inc.</b>",
                               });

var overlay = L.DomUtil.get('overlay');

function awaitGPS() {
  overlay.style.display = 'inline';
  window.setTimeout(function() {overlay.style.opacity = 1;}, 100);
}

function acquiredGPS() {
  overlay.style.opacity = 0;
  window.setTimeout(function() {overlay.style.display = 'none';}, 1000);
  
  if (loadedInterface)
    message.show('MotionDna is initializing your location! Please walk around to help us locate you. If you want to set a custom location and heading instead, click the gear icon.', 300000);
  else
    message.show('MotionDna is initializing your location! Please walk around to help us locate you.', 300000);
}

function acquiredLocation() {
  overlay.style.opacity = 0;
  window.setTimeout(function() {overlay.style.display = 'none';}, 1000);
  
  if (customizingLocation || customizingRotation) return;
  message.show('Location has been initialized!', 5000);
}

// ===== EXTERNS =====

addMap = function(url, options) {
  if (typeof options == "string")
    options = JSON.parse(options);
  options.attribution = 'Motion DNA Locations &copy; <a href="' + NAVISENS_URL + '">Navisens, Inc.</a> | ' + (options.attribution || '');
  L.tileLayer(url, options).addTo(map);
};

addMap_OpenStreetMap_Mapnik = function() {
  addMap('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
         detectRetina: true,
         maxZoom: 19,
         attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
         });
};

addMap_OpenStreetMap_France = function() {
  addMap('https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png', {
         detectRetina: true,
         maxZoom: 20,
         attribution: '&copy; Openstreetmap France | &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
         });
};

addMap_Thunderforest = function(key, mapid) {
  if (key === undefined) return;
  if (mapid === undefined) mapid = 'outdoors';
  addMap('https://{s}.tile.thunderforest.com/{id}/{z}/{x}/{y}.png?apikey={apikey}', {
         detectRetina: true,
         attribution: '&copy; <a href="https://www.thunderforest.com/">Thunderforest</a>, &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
         apikey: key,
         maxZoom: 22,
         id: mapid
         });
};

addMap_Mapbox = function(key, mapid) {
  if (key === undefined) return;
  if (mapid === undefined) mapid = 'mapbox.streets';
  addMap('https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token={accessToken}', {
         detectRetina: true,
         attribution: 'Map data &copy; <a href="https://openstreetmap.org">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery &copy; <a href="https://mapbox.com">Mapbox</a>',
         maxZoom: 23,
         id: mapid,
         accessToken: key
         });
};

addMap_Esri = function() {
  addMap('https://services.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}', {
         detectRetina: true,
         maxZoom: 19 // 24
         });
}

setSimple = function() {
  simpleMode = true; // hack - currently local does not support ui
}

hideClustering = function() {
  clusterMode = false;
}

move = function(id, x, y, heading, category) {
  if (userID == '') return;
  if (!(id in users)) {
    var user = L.marker(GET('usercoords'));
    var userIcon;
    if (id == userID) {
      userIcon = new L.Icon.MarkerUser();
      user.opacity = 0.8;
    } else {
      userIcon = new L.Icon.MarkerOtherUser();
      userIcon.hex = '#' + id.substring(0, 6);
      user.opacity = 0.7;
    }
    user.addTo(map);
    
    users[id] = [user, userIcon];
  }
  var user = users[id][0];
  var userIcon = users[id][1];
  user.setLatLng([x, y]);
  userIcon.category = category;
  userIcon.heading = heading;
  user.setIcon(userIcon);
  
  if (id == userID) {
    if (customizingRotation)
      customRotation.setLatLng([x, y]);
    if (!touching && GET('shouldPan'))
      map.panTo(user.getLatLng());
    
    var nextColor = MOTIONS[category];
    if (nextColor == 0)
      if (currentColor < 180)
        nextColor = 0;
      else
        nextColor = 360;
      else
        if (currentColor - nextColor > 180)
          nextColor += 360;
        else if (nextColor - currentColor > 180)
          nextColor -= 360;
    
    currentColor = L.Util.wrapNum(Math.round((1 - SMOOTH_COLORS) * currentColor + SMOOTH_COLORS * nextColor), [0, 360]);
  }
};

addPoint = function(id, x, y, category) {
  if (!debug || id != userID) return;
  if (volatileLocation) {
    if (volatileLocation.distanceTo([x, y]) < volatileDistance || volatileSamples > MAX_SAMPLES) {
      volatileLocation = null;
    } else {
      volatileSamples++;
      return;
    }
  }
  if (overflowed) return;
  if (clusterMode) {
    if (recentPoints.point && recentPoints.point.equals([x, y], MIN_DISTANCE)) {
      if (category in recentPoints.markers) {
        recentPoints.markers[category].weight++;
      } else {
        var marker = new PruneCluster.Marker(x, y);
        marker.category = category;
        marker.weight = 1;
        pruneCluster.RegisterMarker(marker);
        recentPoints.markers[category] = marker;
        polyline.addLatLng([x, y]);
      }
      pruneCluster.ProcessView();
    } else {
      if (recentPoints.point) {
        var point = {'p': recentPoints.point, 'd': []};
        for (var i = 0, l = MOTIONS.length; i < l; i++)
          if (recentPoints.markers[i])
            point.d.push({'c': recentPoints.markers[i].category, 'w': recentPoints.markers[i].weight});
        allPoints.push(point)
      }
      
      var marker = new PruneCluster.Marker(x, y);
      marker.category = category;
      marker.weight = 1;
      pruneCluster.RegisterMarker(marker);
      pruneCluster.ProcessView();
      polyline.addLatLng([x, y]);
      
      recentPoints.point = L.point(x, y);
      recentPoints.markers = [];
      recentPoints.markers[category] = marker;
    }
  } else {
    if (!recentPoint || !recentPoint.equals([x, y], MIN_DISTANCE)) {
      recentPoint = L.point(x, y);
      
      polyline.addLatLng([x, y]);
    }
  }
};

function SET_ID(id) {
  userID = id;
}

function DEBUG() {
  debug = true;
}

function ADD_BEACON(lat, lng) {
  var beacon = L.marker([lat, lng], {opacity: 0.75});
  beacon.setIcon(new L.Icon.MarkerBeacon());
  beacon.addTo(map);
}

var naviPoints = {};

function ADD_POINT(id, lat, lng) {
  var point = L.marker([lat, lng], {opacity: 0.75});
  var html = "<center><a onclick='CLICK_POINT(\""+ id + "\");' style='color: #1a0dab; text-decoration: none;'><b>Check in</b></a> to<br><i>" + id + "</i>?</center>";
  point.bindPopup(html);
  point.addTo(map);
  naviPoints[id] = point;
}

function CLICK_POINT(id) {
  if (id in naviPoints) {
    volatileLocation = naviPoints[id].getLatLng();
    volatileDistance = volatileLocation.distanceTo(users[userID][0].getLatLng()) / 2;
    if (volatileDistance < MIN_DISTANCE)
      volatileDistance = MIN_DISTANCE;
    volatileSamples = 0;
    
    webkit.messageHandlers.customLocationInitialized.postMessage([naviPoints[id].getLatLng().lat, naviPoints[id].getLatLng().lng, users[userID][1].heading]);
  }
}

function REMOVE_POINT(id) {
  if (id in naviPoints) {
    naviPoints[id].removeFrom(map);
    delete naviPoints[id];
  }
}

var naviRoute = L.polyline([]);

function SHOW_ROUTE(route) {
  CLEAR_ROUTE();
  naviRoute = L.polyline.antPath(route, {"delay": 500, "dashArray": [1, 25], "weight": 5, "color": "TRANSPARENT", "pulseColor": NAVISENS_ORANGE}).addTo(map);
}

function CLEAR_ROUTE() {
  naviRoute.removeFrom(map);
}

function RUN(needsGPS) {
  if (map)
    map.remove();
  
  var options = {
  zoomDelta: 0.5,
  zoomSnap: 0
  };
  
  if (simpleMode) {
    options.crs = L.CRS.Simple;
    options.minZoom = -5;
    options.maxZoom = 10;
    
    map = L.map('map', options).setView(GET('coords'), 5);
    
    L.simpleGraticule({
                      interval: 10000,
                      showshowOriginLabel: true,
                      redraw: 'move',
                      zoomIntervals: [
                                      {start: -5, end: -3, interval: 10000},
                                      {start: -2, end: -1, interval: 1000},
                                      {start: 0, end: 1, interval: 100},
                                      {start: 2, end: 3, interval: 10},
                                      {start: 4, end: 5, interval: 5},
                                      {start: 6, end: 10, interval: 1}
                                      ]}).addTo(map);
  } else {
    map = L.map('map', options).setView(GET('coords'), GET('zoom'));
  }
  
  // ===== DRAWING =====
  
  recentPoints = {'point': null, 'markers': []};
  
  for (var i = 0, l = GET('points') || 1; i < l; i++) {
    allPoints = GET('point.' + i, true);
    
    if (i == l - 1) {
      polyline = L.polyline([], {smoothFactor: 0.8, color: '#111', opacity: 0.5, weight: 1.5}).addTo(map);
    } else {
      polyline = L.polyline([], {smoothFactor: 0.8, color: '#555', opacity: 0.5, weight: 0.8}).addTo(map);
    }
    
    for (var j = 0, m = allPoints.length; j < m; j++) {
      var point = allPoints[j];
      for (var k = 0, n = point.d.length; k < n; k++) {
        var marker = new PruneCluster.Marker(point.p.x, point.p.y);
        marker.category = point.d[k].c;
        marker.weight = point.d[k].w;
        pruneCluster.RegisterMarker(marker);
      }
      polyline.addLatLng([point.p.x, point.p.y]);
    }
  }
  pruneCluster.ProcessView();
  
  map.addLayer(pruneCluster);
  
  // ===== CONTROLS =====
  
  center.addTo(map);
  toggleShouldPan(GET('shouldPan'));
  
  credits.addTo(map);
  
  message.addTo(map);
  
  if (needsGPS)
    awaitGPS();
  
  // console.log("Loaded JS");
  
  SESSION_RELOADED = true;
}

function UI() {
  if (loadedInterface) return;
  loadedInterface = true;
  
  if (simpleMode) return console.log('Attempt to enable controls while in local mode was ignored!');
  
  map.getContainer().addEventListener("touchstart", function (e) { touching = true; touchstart = L.point([e.touches[0].clientX, e.touches[0].clientY]); });
  map.getContainer().addEventListener("touchend", function (e) { window.setTimeout(function () {touching = false;}, 0); });
  
  // ===== INTERFACE =====
  
  customRotationIcon = new L.Icon.MarkerCustomRotation();
  map.on('click', onMapClick);
  map.on('contextmenu', onMapLongClick);
  
  // ===== CONTROLS =====
  
  toggle.addTo(map);
}

