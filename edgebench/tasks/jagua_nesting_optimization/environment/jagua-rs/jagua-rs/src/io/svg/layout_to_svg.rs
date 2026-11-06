use crate::collision_detection::hazards::HazardEntity;
use crate::collision_detection::hazards::collector::BasicHazardCollector;
use crate::collision_detection::hazards::filter::NoFilter;
use crate::entities::{Instance, Layout, LayoutSnapshot};
use crate::geometry::geo_traits::Transformable;
use crate::geometry::primitives::{Circle, Edge, Rect};
use crate::geometry::{DTransformation, Transformation};
use crate::io::export::int_to_ext_transformation;
use crate::io::svg::svg_util;
use crate::io::svg::svg_util::SvgDrawOptions;
use log::warn;
use std::hash::{DefaultHasher, Hash, Hasher};
use svg::Document;
use svg::node::element::{Definitions, Group, Text, Title, Use};

pub fn s_layout_to_svg(
    s_layout: &LayoutSnapshot,
    instance: &impl Instance,
    options: SvgDrawOptions,
    title: &str,
) -> Document {
    let layout = Layout::from_snapshot(s_layout);
    layout_to_svg(&layout, instance, options, title)
}

pub fn layout_to_svg(
    layout: &Layout,
    instance: &impl Instance,
    options: SvgDrawOptions,
    title: &str,
) -> Document {
    let (group, bbox) = layout_to_svg_group(layout, instance, options, title);

    let vbox = bbox.scale(1.1);
    let vbox_svg = format!(
        "{} {} {} {}",
        vbox.x_min,
        vbox.y_min,
        vbox.width(),
        vbox.height()
    );

    Document::new().set("viewBox", vbox_svg).add(group)
}

#[allow(clippy::too_many_lines)]
pub fn layout_to_svg_group(
    layout: &Layout,
    instance: &impl Instance,
    options: SvgDrawOptions,
    title: &str,
) -> (Group, Rect) {
    let container = &layout.container;

    let bbox = container
        .outer_orig
        .bbox()
        .resize_by(
            container.outer_orig.bbox().height() * 0.01,
            container.outer_orig.bbox().height() * 0.01,
        )
        .unwrap();

    let theme = &options.theme;

    let stroke_width =
        f32::min(bbox.width(), bbox.height()) * 0.001 * theme.stroke_width_multiplier;

    let label = {
        //print some information on above the left top of the container
        let bbox = container.outer_orig.bbox();

        let label_content = format!(
            "h: {:.3} | w: {:.3} | d: {:.3}% | {}",
            bbox.height(),
            bbox.width(),
            layout.density(instance) * 100.0,
            title,
        );
        Text::new(label_content)
            .set("x", bbox.x_min)
            .set(
                "y",
                bbox.y_min - 0.5 * 0.025 * f32::min(bbox.width(), bbox.height()),
            )
            .set("font-size", f32::min(bbox.width(), bbox.height()) * 0.025)
            .set("font-family", "monospace")
            .set("font-weight", "500")
    };

    let highlight_cd_shape_style = &[
        ("fill", "none"),
        ("stroke-width", &*format!("{}", 0.5 * stroke_width)),
        ("stroke", "black"),
        ("stroke-opacity", "0.3"),
        (
            "stroke-dasharray",
            &*format!("{} {}", 1.0 * stroke_width, 2.0 * stroke_width),
        ),
        ("stroke-linecap", "round"),
        ("stroke-linejoin", "round"),
    ];

    //draw container
    let container_group = {
        let container_group = Group::new().set("id", format!("container_{}", container.id));
        let bbox = container.outer_orig.bbox();
        let title = Title::new(format!(
            "container, id: {}, bbox: [x_min: {:.3}, y_min: {:.3}, x_max: {:.3}, y_max: {:.3}]",
            container.id, bbox.x_min, bbox.y_min, bbox.x_max, bbox.y_max
        ));

        //outer
        container_group
            .add(svg_util::data_to_path(
                svg_util::original_shape_data(
                    &container.outer_orig,
                    &container.outer_cd,
                    options.draw_cd_shapes,
                ),
                &[
                    ("fill", &*format!("{}", theme.container_fill)),
                    ("stroke", "black"),
                    ("stroke-width", &*format!("{}", 2.0 * stroke_width)),
                ],
            ))
            .add(title)
    };

    let quality_zones_group = {
        let mut qz_group = Group::new().set("id", "quality_zones");

        //quality zones
        for qz in container.quality_zones.iter().rev().flatten() {
            let color = theme.qz_fill[qz.quality];
            let stroke_color = svg_util::change_brightness(color, 0.5);
            for (orig_qz_shape, intern_qz_shape) in qz.shapes_orig.iter().zip(qz.shapes_cd.iter()) {
                qz_group = qz_group.add(
                    svg_util::data_to_path(
                        svg_util::original_shape_data(
                            orig_qz_shape,
                            intern_qz_shape,
                            options.draw_cd_shapes,
                        ),
                        &[
                            ("fill", &*format!("{color}")),
                            ("fill-opacity", "0.50"),
                            ("stroke", &*format!("{stroke_color}")),
                            ("stroke-width", &*format!("{}", 2.0 * stroke_width)),
                            ("stroke-opacity", &*format!("{}", theme.qz_stroke_opac)),
                            ("stroke-dasharray", &*format!("{}", 5.0 * stroke_width)),
                            ("stroke-linecap", "round"),
                            ("stroke-linejoin", "round"),
                        ],
                    )
                    .add(Title::new(format!("quality zone, q: {}", qz.quality))),
                );
            }
        }
        qz_group
    };

    //draw items
    let (items_group, surrogate_group, mut highlight_cd_shape_group) = {
        //define all the items and their surrogates (if enabled)
        let mut item_defs = Definitions::new();
        let mut surrogate_defs = Definitions::new();
        for item in instance.items() {
            let color = match item.min_quality {
                None => theme.item_fill,
                Some(q) => svg_util::blend_colors(theme.item_fill, theme.qz_fill[q]),
            };
            item_defs = item_defs.add(Group::new().set("id", format!("item_{}", item.id)).add(
                svg_util::data_to_path(
                    svg_util::original_shape_data(
                        &item.shape_orig,
                        &item.shape_cd,
                        options.draw_cd_shapes,
                    ),
                    &[
                        ("fill", &*format!("{color}")),
                        ("stroke-width", &*format!("{stroke_width}")),
                        ("fill-rule", "nonzero"),
                        ("stroke", "black"),
                        ("fill-opacity", "0.5"),
                    ],
                ),
            ));

            let int_transf = if options.draw_cd_shapes {
                Transformation::empty()
            } else {
                // The original shape is drawn on the SVG, we need to inverse the pre-transform
                let pre_transform = item.shape_orig.pre_transform.compose();
                pre_transform.inverse()
            };

            if options.surrogate {
                let mut surrogate_group = Group::new().set("id", format!("surrogate_{}", item.id));
                let poi_style = [
                    ("fill", "black"),
                    ("fill-opacity", "0.1"),
                    ("stroke", "black"),
                    ("stroke-width", &*format!("{stroke_width}")),
                    ("stroke-opacity", "0.8"),
                ];
                let ff_style = [
                    ("fill", "none"),
                    ("stroke", "black"),
                    ("stroke-width", &*format!("{stroke_width}")),
                    ("stroke-opacity", "0.8"),
                ];
                let no_ff_style = [
                    ("fill", "none"),
                    ("stroke", "black"),
                    ("stroke-width", &*format!("{stroke_width}")),
                    ("stroke-opacity", "0.5"),
                    ("stroke-dasharray", &*format!("{}", 5.0 * stroke_width)),
                    ("stroke-linecap", "round"),
                    ("stroke-linejoin", "round"),
                ];

                let surrogate = item.shape_cd.surrogate();
                let poi = &surrogate.poles[0];
                let ff_poles = surrogate.ff_poles();

                for pole in &surrogate.poles {
                    if pole == poi {
                        let svg_circle =
                            svg_util::circle(pole.transform_clone(&int_transf), &poi_style);
                        surrogate_group = surrogate_group.add(svg_circle);
                    } else if ff_poles.contains(pole) {
                        let svg_circle =
                            svg_util::circle(pole.transform_clone(&int_transf), &ff_style);
                        surrogate_group = surrogate_group.add(svg_circle);
                    } else {
                        let svg_circle =
                            svg_util::circle(pole.transform_clone(&int_transf), &no_ff_style);
                        surrogate_group = surrogate_group.add(svg_circle);
                    }
                }
                for pier in &surrogate.piers {
                    surrogate_group = surrogate_group.add(svg_util::data_to_path(
                        svg_util::edge_data(pier.transform_clone(&int_transf)),
                        &ff_style,
                    ));
                }
                surrogate_defs = surrogate_defs.add(surrogate_group);
            }

            if options.highlight_cd_shapes {
                let t_shape_cd = item.shape_cd.transform_clone(&int_transf);
                //draw the CD shape with a dotted line, and no fill
                let mut group = Group::new().add(svg_util::data_to_path(
                    svg_util::simple_polygon_data(&t_shape_cd),
                    highlight_cd_shape_style,
                ));
                if options.draw_cd_shapes {
                    //draw all the vertices as dots
                    for p in &t_shape_cd.vertices {
                        let circle = Circle {
                            center: *p,
                            radius: 0.5 * stroke_width,
                        };
                        group = group.add(svg_util::circle(
                            circle,
                            &[("fill", "cyan"), ("fill-opacity", "0.8")],
                        ));
                    }
                }
                let group = group.set("id", format!("cd_shape_{}", item.id));
                item_defs = item_defs.add(group);
            }
        }
        let mut items_group = Group::new().set("id", "items").add(item_defs);
        let mut surrogate_group = Group::new().set("id", "surrogates").add(surrogate_defs);
        let mut highlight_cd_shapes_group = Group::new().set("id", "highlight_cd_shapes");

        for pi in layout.placed_items.values() {
            let dtransf = if options.draw_cd_shapes {
                pi.d_transf
            } else {
                let item = instance.item(pi.item_id);
                int_to_ext_transformation(&pi.d_transf, &item.shape_orig.pre_transform)
            };
            let title = Title::new(format!("item, id: {}, transf: [{}]", pi.item_id, dtransf));
            let pi_ref = Use::new()
                .set("transform", transform_to_svg(dtransf))
                .set("href", format!("#item_{}", pi.item_id))
                .add(title);

            items_group = items_group.add(pi_ref);

            if options.surrogate {
                let pi_surr_ref = Use::new()
                    .set("transform", transform_to_svg(dtransf))
                    .set("href", format!("#surrogate_{}", pi.item_id));

                surrogate_group = surrogate_group.add(pi_surr_ref);
            }
            if options.highlight_cd_shapes {
                let pi_cd_ref = Use::new()
                    .set("transform", transform_to_svg(dtransf))
                    .set("href", format!("#cd_shape_{}", pi.item_id));
                highlight_cd_shapes_group = highlight_cd_shapes_group.add(pi_cd_ref);
            }
        }

        (items_group, surrogate_group, highlight_cd_shapes_group)
    };

    //draw quadtree (if enabled)
    let quad_tree_group = if options.quadtree {
        let qt_data = svg_util::quad_tree_data(&layout.cde().quadtree, &NoFilter);
        let qt_group = Group::new()
            .set("id", "quadtree")
            .add(svg_util::data_to_path(
                qt_data.0,
                &[
                    ("fill", "red"),
                    ("stroke-width", &*format!("{}", stroke_width * 0.25)),
                    ("fill-rule", "nonzero"),
                    ("fill-opacity", "0.6"),
                    ("stroke", "black"),
                ],
            ))
            .add(svg_util::data_to_path(
                qt_data.1,
                &[
                    ("fill", "none"),
                    ("stroke-width", &*format!("{}", stroke_width * 0.25)),
                    ("fill-rule", "nonzero"),
                    ("fill-opacity", "0.3"),
                    ("stroke", "black"),
                ],
            ))
            .add(svg_util::data_to_path(
                qt_data.2,
                &[
                    ("fill", "green"),
                    ("fill-opacity", "0.6"),
                    ("stroke-width", &*format!("{}", stroke_width * 0.25)),
                    ("stroke", "black"),
                ],
            ));
        Some(qt_group)
    } else {
        None
    };

    //highlight colliding items (if enabled)
    let collision_group = if options.highlight_collisions {
        let mut collision_group = Group::new().set("id", "collision_lines");
        for (pk, pi) in &layout.placed_items {
            let collector = {
                let mut collector =
                    BasicHazardCollector::with_capacity(layout.cde().hazards_map.len());
                layout
                    .cde()
                    .collect_poly_collisions(&pi.shape, &mut collector);
                collector.retain(|_, entity| {
                    // filter out the item itself
                    if let HazardEntity::PlacedItem {
                        pk: colliding_pk, ..
                    } = entity
                    {
                        *colliding_pk != pk
                    } else {
                        true
                    }
                });
                collector
            };
            for (_, haz_entity) in &collector {
                match haz_entity {
                    HazardEntity::PlacedItem {
                        pk: colliding_pk, ..
                    } => {
                        let haz_hash = {
                            let mut hasher = DefaultHasher::new();
                            haz_entity.hash(&mut hasher);
                            hasher.finish()
                        };
                        let pi_hash = {
                            let mut hasher = DefaultHasher::new();
                            HazardEntity::from((pk, pi)).hash(&mut hasher);
                            hasher.finish()
                        };

                        if haz_hash < pi_hash {
                            // avoid duplicate lines
                            let start = pi.shape.poi.center;
                            let end = layout.placed_items[*colliding_pk].shape.poi.center;
                            collision_group = collision_group.add(svg_util::data_to_path(
                                svg_util::edge_data(Edge { start, end }),
                                &[
                                    ("stroke", &*format!("{}", theme.collision_highlight_color)),
                                    ("stroke-opacity", "0.75"),
                                    ("stroke-width", &*format!("{}", stroke_width * 4.0)),
                                    (
                                        "stroke-dasharray",
                                        &*format!("{} {}", 4.0 * stroke_width, 8.0 * stroke_width),
                                    ),
                                    ("stroke-linecap", "round"),
                                    ("stroke-linejoin", "round"),
                                ],
                            ));
                        }
                    }
                    HazardEntity::Exterior => {
                        collision_group = collision_group.add(svg_util::point(
                            pi.shape.poi.center,
                            Some(&*format!("{}", theme.collision_highlight_color)),
                            Some(3.0 * stroke_width),
                        ));
                    }
                    _ => {
                        warn!("unexpected hazard entity");
                    }
                }
            }
        }
        Some(collision_group)
    } else {
        None
    };

    if options.highlight_cd_shapes {
        highlight_cd_shape_group = highlight_cd_shape_group.add(svg_util::data_to_path(
            svg_util::simple_polygon_data(&container.outer_cd),
            highlight_cd_shape_style,
        ));
    }

    let optionals = [
        Some(highlight_cd_shape_group),
        Some(surrogate_group),
        quad_tree_group,
        collision_group,
    ]
    .into_iter()
    .flatten()
    .fold(Group::new().set("id", "optionals"), Group::add);

    let combined_group = Group::new()
        .add(container_group)
        .add(items_group)
        .add(quality_zones_group)
        .add(optionals)
        .add(label);

    (combined_group, bbox)
}
fn transform_to_svg(dt: DTransformation) -> String {
    //https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/transform
    //operations are effectively applied from right to left
    let (tx, ty) = dt.translation();
    let r = dt.rotation().to_degrees();
    format!("translate({tx} {ty}), rotate({r})")
}
