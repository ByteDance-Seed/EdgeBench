use crate::collision_detection::hazards::filter::HazardFilter;
use crate::collision_detection::quadtree::{QTHazPresence, QTNode};
use crate::entities::N_QUALITIES;
use crate::geometry;
use crate::geometry::OriginalShape;
use crate::geometry::primitives::{Edge, Point, SPolygon};
use serde::{Deserialize, Deserializer, Serialize, Serializer};
use std::fmt::{Display, Formatter};
use svg::node::element::path::Data;
use svg::node::element::{Circle, Path};

#[allow(clippy::struct_excessive_bools)]
#[derive(Clone, PartialEq, Debug, Serialize, Deserialize, Copy)]
#[serde(default)]
pub struct SvgDrawOptions {
    ///The theme to use for the svg
    pub theme: SvgLayoutTheme,
    ///Draw the quadtree on top
    pub quadtree: bool,
    ///Draw the fail fast surrogate on top of each item
    pub surrogate: bool,
    ///Draw dashed lines between colliding items
    pub highlight_collisions: bool,
    ///Draw the modified shapes used internally instead of the original ones
    pub draw_cd_shapes: bool,
    ///Highlights the shapes used for collision detection with a dashed border
    pub highlight_cd_shapes: bool,
}

impl Default for SvgDrawOptions {
    fn default() -> Self {
        Self {
            theme: SvgLayoutTheme::default(),
            quadtree: false,
            surrogate: false,
            highlight_collisions: true,
            draw_cd_shapes: false,
            highlight_cd_shapes: true,
        }
    }
}

#[derive(Clone, PartialEq, Debug, Serialize, Deserialize, Copy)]
pub struct SvgLayoutTheme {
    pub stroke_width_multiplier: f32,
    pub container_fill: Color,
    pub item_fill: Color,
    pub hole_fill: Color,
    pub qz_fill: [Color; N_QUALITIES],
    pub qz_stroke_opac: f32,
    pub collision_highlight_color: Color,
}

impl Default for SvgLayoutTheme {
    fn default() -> Self {
        SvgLayoutTheme::EARTH_TONES
    }
}

impl SvgLayoutTheme {
    pub const EARTH_TONES: SvgLayoutTheme = SvgLayoutTheme {
        stroke_width_multiplier: 2.0,
        container_fill: Color(0xCC, 0x82, 0x4A),
        item_fill: Color(0xFF, 0xC8, 0x79),
        hole_fill: Color(0x2D, 0x2D, 0x2D),
        qz_fill: [
            Color(0x00, 0x00, 0x00), // BLACK
            Color(0xFF, 0x00, 0x00), // RED
            Color(0xFF, 0x5E, 0x00), // ORANGE
            Color(0xFF, 0xA5, 0x00), // LIGHT ORANGE
            Color(0xC7, 0xA9, 0x00), // DARK YELLOW
            Color(0xFF, 0xFF, 0x00), // YELLOW
            Color(0xCB, 0xFF, 0x00), // GREEN
            Color(0xCB, 0xFF, 0x00), // GREEN
            Color(0xCB, 0xFF, 0x00), // GREEN
            Color(0xCB, 0xFF, 0x00), // GREEN
        ],
        qz_stroke_opac: 0.5,
        collision_highlight_color: Color(0x00, 0xFF, 0x00), // LIME
    };

    pub const GRAY: SvgLayoutTheme = SvgLayoutTheme {
        stroke_width_multiplier: 2.5,
        container_fill: Color(0xD3, 0xD3, 0xD3),
        item_fill: Color(0x7A, 0x7A, 0x7A),
        hole_fill: Color(0xFF, 0xFF, 0xFF),
        qz_fill: [
            Color(0x63, 0x63, 0x63), //GRAY
            Color(0x63, 0x63, 0x63), //GRAY
            Color(0x63, 0x63, 0x63), //GRAY
            Color(0x63, 0x63, 0x63), //GRAY
            Color(0x63, 0x63, 0x63), //GRAY
            Color(0x63, 0x63, 0x63), //GRAY
            Color(0x63, 0x63, 0x63), //GRAY
            Color(0x63, 0x63, 0x63), //GRAY
            Color(0x63, 0x63, 0x63), //GRAY
            Color(0x63, 0x63, 0x63), //GRAY
        ],
        qz_stroke_opac: 0.9,
        collision_highlight_color: Color(0xD0, 0x00, 0x00), //LIME
    };
}

#[allow(clippy::cast_sign_loss, clippy::cast_possible_truncation)]
pub fn change_brightness(color: Color, fraction: f32) -> Color {
    let Color(r, g, b) = color;

    let r = (f32::from(r) * fraction) as u8;
    let g = (f32::from(g) * fraction) as u8;
    let b = (f32::from(b) * fraction) as u8;
    Color(r, g, b)
}

#[allow(clippy::cast_sign_loss, clippy::cast_possible_truncation)]
pub fn blend_colors(color_1: Color, color_2: Color) -> Color {
    //blend color_1 and color_2
    let Color(r_1, g_1, b_1) = color_1;
    let Color(r_2, g_2, b_2) = color_2;

    let r = ((f32::from(r_1) * 0.5) + (f32::from(r_2) * 0.5)) as u8;
    let g = ((f32::from(g_1) * 0.5) + (f32::from(g_2) * 0.5)) as u8;
    let b = ((f32::from(b_1) * 0.5) + (f32::from(b_2) * 0.5)) as u8;

    Color(r, g, b)
}

#[derive(Copy, Clone, PartialEq, Debug)]
pub struct Color(u8, u8, u8);

impl Display for Color {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        write!(f, "#{:02X}{:02X}{:02X}", self.0, self.1, self.2)
    }
}

impl From<String> for Color {
    fn from(mut s: String) -> Self {
        if s.starts_with('#') {
            s.remove(0);
        }
        let r = u8::from_str_radix(&s[0..2], 16).unwrap();
        let g = u8::from_str_radix(&s[2..4], 16).unwrap();
        let b = u8::from_str_radix(&s[4..6], 16).unwrap();
        Color(r, g, b)
    }
}

impl From<&str> for Color {
    fn from(s: &str) -> Self {
        Color::from(s.to_owned())
    }
}

impl Serialize for Color {
    fn serialize<S>(&self, serializer: S) -> Result<<S as Serializer>::Ok, <S as Serializer>::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(&format!("{self}"))
    }
}

impl<'de> Deserialize<'de> for Color {
    fn deserialize<D>(deserializer: D) -> Result<Self, <D as Deserializer<'de>>::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        Ok(Color::from(s))
    }
}

pub fn original_shape_data(
    original: &OriginalShape,
    internal: &SPolygon,
    draw_internal: bool,
) -> Data {
    if draw_internal {
        simple_polygon_data(internal)
    } else {
        simple_polygon_data(&original.shape)
    }
}

pub fn simple_polygon_data(s_poly: &SPolygon) -> Data {
    let mut data = Data::new().move_to::<(f32, f32)>(s_poly.vertex(0).into());
    for i in 1..s_poly.n_vertices() {
        data = data.line_to::<(f32, f32)>(s_poly.vertex(i).into());
    }
    data.close()
}

pub fn quad_tree_data(
    qt_root: &QTNode,
    irrelevant_hazards: &impl HazardFilter,
) -> (Data, Data, Data) {
    qt_node_data(
        qt_root,
        Data::new(),
        Data::new(),
        Data::new(),
        irrelevant_hazards,
    )
}

#[allow(clippy::similar_names)]
fn qt_node_data(
    qt_node: &QTNode,
    mut data_eh: Data, //entire hazards data
    mut data_ph: Data, //partial hazards data
    mut data_nh: Data, //no hazards data
    filter: &impl HazardFilter,
) -> (Data, Data, Data) {
    //Only draw qt_nodes that do not have a child

    if let (Some(children), Some(_)) =
        (qt_node.children.as_ref(), qt_node.hazards.strongest(filter))
    {
        //not a leaf node, go to children
        for child in children.iter() {
            let data = qt_node_data(child, data_eh, data_ph, data_nh, filter);
            data_eh = data.0;
            data_ph = data.1;
            data_nh = data.2;
        }
    } else {
        //leaf node, draw it
        let rect = &qt_node.bbox;
        let draw = |data: Data| -> Data {
            data.move_to((rect.x_min, rect.y_min))
                .line_to((rect.x_max, rect.y_min))
                .line_to((rect.x_max, rect.y_max))
                .line_to((rect.x_min, rect.y_max))
                .close()
        };

        match qt_node.hazards.strongest(filter) {
            Some(ch) => match ch.presence {
                QTHazPresence::Entire => data_eh = draw(data_eh),
                QTHazPresence::Partial(_) => data_ph = draw(data_ph),
                QTHazPresence::None => unreachable!(),
            },
            None => data_nh = draw(data_nh),
        }
    }

    (data_eh, data_ph, data_nh)
}

pub fn data_to_path(data: Data, params: &[(&str, &str)]) -> Path {
    let mut path = Path::new();
    for param in params {
        path = path.set(param.0, param.1);
    }
    path.set("d", data)
}

pub fn point(Point(x, y): Point, fill: Option<&str>, rad: Option<f32>) -> Circle {
    Circle::new()
        .set("cx", x)
        .set("cy", y)
        .set("r", rad.unwrap_or(0.5))
        .set("fill", fill.unwrap_or("black"))
}

pub fn circle(circle: geometry::primitives::Circle, params: &[(&str, &str)]) -> Circle {
    let mut circle = Circle::new()
        .set("cx", circle.center.0)
        .set("cy", circle.center.1)
        .set("r", circle.radius);
    for param in params {
        circle = circle.set(param.0, param.1);
    }
    circle
}

pub fn edge_data(edge: Edge) -> Data {
    Data::new()
        .move_to((edge.start.0, edge.start.1))
        .line_to((edge.end.0, edge.end.1))
}

#[allow(dead_code)]
pub fn aa_rect_data(rect: geometry::primitives::Rect) -> Data {
    Data::new()
        .move_to((rect.x_min, rect.y_min))
        .line_to((rect.x_max, rect.y_min))
        .line_to((rect.x_max, rect.y_max))
        .line_to((rect.x_min, rect.y_max))
        .close()
}
