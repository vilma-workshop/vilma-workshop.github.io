# Generates a synthetic structure-from-motion scene (sparse point cloud +
# registered camera frusta) and emits the ViLMa social card SVG.
# Deterministic: fixed PRNG seed, so re-running produces an identical file.
#
#   ruby script/gen-social-card.rb assets/imgs/social-card.svg
#
# Then export to PNG at 2x. Render natively at the target size rather than
# rendering large and downscaling, which softens the hairline frustum strokes:
#
#   rsvg-convert -w 2400 -h 1260 assets/imgs/social-card.svg \
#     -o assets/imgs/social-card.png
#
# 2400x1260 keeps the 1.91:1 ratio Open Graph expects and stays crisp on
# high-DPI displays; 1200x630 is the spec minimum and visibly soft.

W, H = 1200, 630
RNG = Random.new(20260908)

# ---------------------------------------------------------------- 3D helpers
def sub(a, b)
  [a[0] - b[0], a[1] - b[1], a[2] - b[2]]
end
def dot(a, b)
  a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
end
def cross(a, b)
  [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
end
def norm(a)
  m = Math.sqrt(dot(a, a))
  [a[0] / m, a[1] / m, a[2] / m]
end

# Viewer: an orbiting eye looking at the scene, like a COLMAP viewport.
EYE    = [3.4, 2.9, -4.2]
TARGET = [0.1, 1.15, 3.6]
FWD    = norm(sub(TARGET, EYE))
RIGHT  = norm(cross(FWD, [0, 1, 0]))
UP     = cross(RIGHT, FWD)
FOCAL  = 900.0
CX, CY = 880.0, 298.0

# Returns [x, y, depth] in card coordinates, or nil if behind the viewer.
def project(p)
  d = sub(p, EYE)
  z = dot(d, FWD)
  return nil if z < 0.35
  [CX + FOCAL * dot(d, RIGHT) / z, CY - FOCAL * dot(d, UP) / z, z]
end

def jitter(s)
  (RNG.rand - 0.5) * s
end

# ------------------------------------------------------------- scene points
points = []

# Facade: a wall of tracked features, denser around windows.
64.times do |i|
  26.times do |j|
    next if RNG.rand > 0.64
    x = -3.6 + i * 0.185 + jitter(0.05)
    y = 0.08 + j * 0.135 + jitter(0.05)
    points << [[x, y, 6.1 + jitter(0.16)], :structure]
  end
end

# Return wall at an angle, giving the cloud some depth.
26.times do |i|
  22.times do |j|
    next if RNG.rand > 0.52
    z = 2.0 + i * 0.16 + jitter(0.06)
    y = 0.05 + j * 0.14 + jitter(0.05)
    points << [[-3.75 + jitter(0.14), y, z], :structure]
  end
end

# Ground plane: sparser, noisier, as real SfM ground tends to be.
3100.times do
  x = -6.5 + RNG.rand * 18.0
  z = 0.8 + RNG.rand * 8.6
  points << [[x, 0.02 + jitter(0.07), z], :ground]
end

# A few floating outliers - every real reconstruction has them.
95.times do
  points << [[-4.5 + RNG.rand * 9.0, 0.3 + RNG.rand * 3.4, 1.0 + RNG.rand * 6.5], :outlier]
end

# ------------------------------------------------------------------ cameras
# Registered views along a capture trajectory arcing past the facade.
cams = (0...9).map do |i|
  t = i / 8.0
  c = [-3.1 + t * 6.2, 1.28 + Math.sin(t * Math::PI) * 0.34, 0.55 + Math.sin(t * Math::PI) * 0.75]
  [c, norm(sub([jitter(0.5), 1.2, 5.9], c))]
end

def frustum(c, fwd, scale: 0.42, depth: 0.62)
  r = norm(cross(fwd, [0, 1, 0]))
  u = cross(r, fwd)
  centre = (0..2).map { |k| c[k] + fwd[k] * depth }
  corners = [[-1, -0.72], [1, -0.72], [1, 0.72], [-1, 0.72]].map do |sx, sy|
    (0..2).map { |k| centre[k] + r[k] * sx * scale + u[k] * sy * scale }
  end
  [c, corners]
end

# ------------------------------------------------------------------- output
svg = []
svg << %(<svg xmlns="http://www.w3.org/2000/svg" width="#{W}" height="#{H}" viewBox="0 0 #{W} #{H}">)
svg << <<~DEFS
    <defs>
      <linearGradient id="bg" x1="0" y1="0" x2="#{W}" y2="#{H}" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#0f7350"/>
        <stop offset="1" stop-color="#12456f"/>
      </linearGradient>
      <!-- Luminance mask: the cloud is a faint texture behind the headline and
           resolves to full detail on the right, so the text stays legible. -->
      <linearGradient id="reveal" x1="0" y1="0" x2="#{W}" y2="0" gradientUnits="userSpaceOnUse">
        <stop offset="0.00" stop-color="#404040"/>
        <stop offset="0.40" stop-color="#707070"/>
        <stop offset="0.72" stop-color="#cccccc"/>
        <stop offset="1.00" stop-color="#ffffff"/>
      </linearGradient>
      <mask id="revealRight">
        <rect width="#{W}" height="#{H}" fill="url(#reveal)"/>
      </mask>
      <!-- Light scrim for text contrast, much weaker now the mask does the work. -->
      <linearGradient id="scrim" x1="0" y1="0" x2="#{W}" y2="0" gradientUnits="userSpaceOnUse">
        <stop offset="0.00" stop-color="#0c2b45" stop-opacity="0.58"/>
        <stop offset="0.45" stop-color="#0c2b45" stop-opacity="0.30"/>
        <stop offset="0.78" stop-color="#0c2b45" stop-opacity="0.08"/>
        <stop offset="1.00" stop-color="#0c2b45" stop-opacity="0.00"/>
      </linearGradient>
      <linearGradient id="fade" x1="0" y1="#{H}" x2="0" y2="#{H * 0.45}" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#0c2b45" stop-opacity="0.55"/>
        <stop offset="1" stop-color="#0c2b45" stop-opacity="0"/>
      </linearGradient>
    </defs>
    <rect width="#{W}" height="#{H}" fill="url(#bg)"/>
DEFS

svg << %(  <g id="reconstruction" mask="url(#revealRight)">)

# Depth-sorted so nearer points overdraw farther ones.
drawn = 0
points.map { |p, kind| (pr = project(p)) && [pr, kind] }.compact
      .select { |(x, y, _), _| x > -60 && x < W + 60 && y > -60 && y < H + 60 }
      .sort_by { |(_, _, z), _| -z }
      .each do |(x, y, z), kind|
  drawn += 1
  r  = (FOCAL * 0.029 / z).round(2).clamp(1.6, 4.9)
  op = (7.0 / z).round(3).clamp(0.34, 0.92)
  fill = case kind
         when :ground  then "#bfe8dc"
         when :outlier then "#ffd9a8"
         else "#eaf7ff"
         end
  op *= 0.62 if kind == :ground
  svg << %(    <circle cx="#{x.round(1)}" cy="#{y.round(1)}" r="#{r}" fill="#{fill}" opacity="#{op.round(3)}"/>)
end

# Trajectory through the camera centres.
traj = cams.map { |c, _| project(c) }.compact.map { |x, y, _| "#{x.round(1)},#{y.round(1)}" }
svg << %(    <polyline points="#{traj.join(' ')}" fill="none" stroke="#ffffff" stroke-opacity="0.30" stroke-width="1.6" stroke-dasharray="5 5"/>)

# COLMAP-style red wireframe frusta.
cams.each do |c, fwd|
  apex, corners = frustum(c, fwd)
  pa = project(apex)
  pc = corners.map { |k| project(k) }
  next if pa.nil? || pc.any?(&:nil?)
  quad = pc.map { |x, y, _| "#{x.round(1)},#{y.round(1)}" }.join(" ")
  svg << %(    <g stroke="#ff6b6b" stroke-opacity="0.85" stroke-width="1.5" fill="none" stroke-linejoin="round">)
  svg << %(      <polygon points="#{quad}" fill="#ff6b6b" fill-opacity="0.07"/>)
  pc.each { |x, y, _| svg << %(      <line x1="#{pa[0].round(1)}" y1="#{pa[1].round(1)}" x2="#{x.round(1)}" y2="#{y.round(1)}"/>) }
  svg << %(    </g>)
end

svg << %(  </g>)
svg << %(  <rect width="#{W}" height="#{H}" fill="url(#scrim)"/>)
svg << %(  <rect width="#{W}" height="#{H}" fill="url(#fade)"/>)

FONT = "Open Sans, Helvetica Neue, Helvetica, Arial, sans-serif"
svg << <<~TEXT
    <g transform="translate(80 74)">
      <rect width="88" height="88" rx="20" fill="#ffffff" fill-opacity="0.14" stroke="#ffffff" stroke-opacity="0.45" stroke-width="2"/>
      <path d="M23 26 L44 62 L65 26" fill="none" stroke="#fff" stroke-width="11" stroke-linecap="round" stroke-linejoin="round"/>
    </g>
    <text x="192" y="132" fill="#ffffff" font-family="#{FONT}" font-size="40" font-weight="700" letter-spacing="6">ViLMa</text>
    <text x="80" y="272" fill="#ffffff" font-family="#{FONT}" font-size="62" font-weight="700">2nd Workshop on Visual</text>
    <text x="80" y="348" fill="#ffffff" font-family="#{FONT}" font-size="62" font-weight="700">Localization and Mapping</text>
    <text x="80" y="424" fill="#ffffff" fill-opacity="0.88" font-family="#{FONT}" font-size="38">From Optimization to 3D Foundation Models</text>
    <rect x="80" y="478" width="132" height="4" rx="2" fill="#ffffff" fill-opacity="0.55"/>
    <text x="80" y="548" fill="#ffffff" fill-opacity="0.82" font-family="#{FONT}" font-size="32" font-weight="600">ECCV 2026  &#183;  Malm&#246;, Sweden  &#183;  8 September 2026</text>
TEXT

svg << "</svg>"

out = ARGV[0]
File.write(out, svg.join("\n") + "\n")
warn "  points generated: #{points.size}, drawn on canvas: #{drawn}"
warn "  camera frusta: #{cams.size}"
warn "  file: #{out} (#{(File.size(out) / 1024.0).round(1)} KB)"
