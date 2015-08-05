/* A collection of OpenSCAD fucntions I use in my designs. This code is in the public domain unless otherwise marked.
 * 
 * All comments welcome
 * 
 * Ian Gibbs <realflash.uk@googlemail.com> */


// Things you probably shouldn't change
resolution = 0.5;

// A cuboid with corners rounded in the z-axis
module rounded_rect(size, radius) 
{
	x = size[0];
	y = size[1];
	z = size[2];

	linear_extrude(height=z)
	hull()
	{
		translate([radius, radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);

		translate([x - radius, radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);

		translate([x - radius, y - radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);

		translate([radius, y - radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);
	}
}

// A high resolution cylinder
module fine_cylinder(dia, length)
{
	cylinder(length, dia/2, dia/2, $fs = resolution, $fa = resolution);
}

// A high resolution circle
module fine_circle(dia, length)
{
	circle(d = dia, $fs = resolution, $fa = resolution);
}

// A high resolution conde
module fine_cone(dia, dia2, length)
{
	cylinder(length, dia/2, dia2/2, $fs = resolution, $fa = resolution);
}

// A pyramid with a rectangular base x * y, of height z
module square_pyramid(size)
{
	x = size[0];
	y = size[1];
	z = size[2];

	polyhedron(points=[ [x/2,y/2,0],[x/2,-y/2,0],[-x/2,-y/2,0],[-x/2,y/2,0],	// the four points at base
      							[0,0,z]  ],                 	// the apex point 
  		triangles=[ [0,1,4],[1,2,4],[2,3,4],[3,0,4],    			// each triangle side
      					[1,0,3],[2,1,3] ],                  		// two triangles for square base
  		sides=[ [0,1,4],[1,2,4],[2,3,4],[3,0,4],    				// same again for alter versions of OpenSCAD
      					[1,0,3],[2,1,3] ]                  		
 		);
}

// A cuboid with the two corners at the x-most end rounded off in the z-axis
module rounded_tab(size, radius) 
{
	x = size[0];
	y = size[1];
	z = size[2];

	linear_extrude(height=z)
	hull()
	{
		square([x/10,y]);

		translate([x - radius, radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);

		translate([x - radius, y - radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);
	}
}

/**
 * pie.scad
 *
 * Use this module to generate a pie- or pizza- slice shape, which is particularly useful
 * in combination with `difference()` and `intersection()` to render shapes that extend a
 * certain number of degrees around or within a circle.
 *
 * This openSCAD library is part of the [dotscad](https://github.com/dotscad/dotscad)
 * project.
 *
 * @copyright  Chris Petersen, 2013
 * @license    http://creativecommons.org/licenses/LGPL/2.1/
 * @license    http://creativecommons.org/licenses/by-sa/3.0/
 *
 * @see        http://www.thingiverse.com/thing:109467
 * @source     https://github.com/dotscad/dotscad/blob/master/pie.scad
 *
 * @param float radius Radius of the pie
 * @param float angle  Angle (size) of the pie to slice
 * @param float height Height (thickness) of the pie
 * @param float spin   Angle to spin the slice on the Z axis
 */
module pie(radius, angle, height, spin=0) {
    // Negative angles shift direction of rotation
    clockwise = (angle < 0) ? true : false;
    // Support angles < 0 and > 360
    normalized_angle = abs((angle % 360 != 0) ? angle % 360 : angle % 360 + 360);
    // Select rotation direction
    rotation = clockwise ? [0, 180 - normalized_angle] : [180, normalized_angle];
    // Render
    if (angle != 0) {
        rotate([0,0,spin]) linear_extrude(height=height)
            difference() {
                circle(radius, $fn=100);
                if (normalized_angle < 180) {
                    union() for(a = rotation)
                        rotate(a) translate([-radius, 0, 0]) square(radius * 2);
                }
                else if (normalized_angle != 360) {
                    intersection_for(a = rotation)
                        rotate(a) translate([-radius, 0, 0]) square(radius * 2);
                }
            }
    }
}

// A six-sided cylinder that cun be subtracted from another shape to create something
// you can trap a hexagonal nut in
//
// dia is the distance from nut flat to nut flat, rather than the longer
// vertex to vertex distance. It's the distance you would naturally try to measure first,
// and the size of the socket or spanner you would use to tighten it.
module nut_capture(dia, thickness)
{
	// Convert the flat-to-flat distance to the radius of the circle that will encompass it
	// The nut can be drawn as 12 right angle triangles, each with a 30 degree angle at the 
	// centre of the nut. The adjacent size is half the flat-to-flat distance, and the hypotenuse
	// is the radius that will enclose the nut.
	rad = (dia/2)/cos(30);
	cylinder(h=thickness,r=rad, $fn=6);
}

// A knob to go on the hexagonal head of a bolt so that you can turn it/tighten it
// easily with your hand
//
// Adapted from and with thanks to http://www.thingiverse.com/thing:7979/#files	
// license at that link applies
module knob(nut_od, nut_height, bolt_od,)
{
	num_dents = 6;
	dent_offset = 2;
	nut_wall_thickness = 1.2;
	knob_height = nut_height+nut_wall_thickness;
	nut_hole_radius = bolt_od/2; 
	nut_size_radius = nut_od/2; 
	knob_radius = nut_size_radius*2.5;
	dent_radius = knob_radius*0.35;

	translate([0, 0, 0]) {
		difference() {
		cylinder(h = knob_height, r = knob_radius);
		for (i = [0:(num_dents - 1)]) {
			translate([sin(360*i/num_dents)*(knob_radius+dent_offset), cos(360*i/num_dents)*(knob_radius+dent_offset), -5 ])
			cylinder(h = knob_height+10, r=dent_radius);
			}
		translate([0,0,-5]) cylinder(h = knob_height+10, r=nut_hole_radius,$fa=10);
		translate([0,0,nut_wall_thickness]) cylinder(h = knob_height+10, r=nut_size_radius,$fa=60);
		}
	}
}

// a 3D trapezium
module trapezium(base,top,height,thickness)
{
	top_offset = (base-top)/2;
	linear_extrude(height=thickness) 
		polygon(points=[[0,0],[base,0],[base-top_offset,height],[top_offset,height]]);
}

// A 3D trapezium with the top corners rounded off in the z-axis
module rounded_top_trapezium(base, top, height, thickness, corner_diameter)
{
	top_offset = (base-top)/2;
	corner_rad = corner_diameter/2;
	unrounded_dia = 0.1;
	translate([0,unrounded_dia/2,0]) hull()
	{
		fine_cylinder(unrounded_dia, thickness);
		translate([base-unrounded_dia,0,0])
			fine_cylinder(unrounded_dia, thickness);
		translate([base-top_offset-corner_rad,height-corner_rad,0])
			fine_cylinder(corner_diameter, thickness);
		translate([top_offset+corner_rad,height-corner_rad,0])
			fine_cylinder(corner_diameter, thickness);
	}
}

// A doughnut
module doughnut(dia, thickness)
{
	rotate_extrude(convexity = 1,$fn=100)
	{
		translate([dia/2,0,0])
			circle(r=thickness/2,$fn=100);
	}

}

// A doughnut by radius instead of diameter
// Stupid historic duplication
module ring(radius, thickness)
{
	rotate_extrude(convexity = 1,$fn=100)
	{
		translate([radius,0,0])		
			circle(r=thickness,$fn=100);
	}
}

// What you get if you cut down through an apple
module sphere_slice(slice_radius, thickness)
{
	sphere_radius = ((pow(slice_radius, 2) - pow(thickness, 2))/2)/thickness;
	translate([0,0,-sphere_radius+thickness])	difference()
	{
		sphere(r=sphere_radius, $fn = 100);
		translate([0,0,-thickness]) cube(2*sphere_radius, center=true);
	}
}

// What you get if slice a sausage lengthways
module cylinder_slice(slice_width, slice_length, slice_height)
{
	
	cylinder_radius = ((pow(slice_width, 2) - pow(slice_height, 2))/2)/slice_height;
	rotate([90,0,90])
		translate([slice_width,-cylinder_radius+slice_height,0])	
		difference()
	{
			fine_cylinder(cylinder_radius*2, slice_length);
		translate([0,-cylinder_radius-slice_height,slice_length*0.5])
			cube([4*cylinder_radius,4*cylinder_radius,slice_length*1.1], center=true);
	}
}

// A slot you can subtract from another shape with rounded ends, such as for a
// screw mounting point
module rounded_slot(od, length, thickness)
{
    hull()
    {
        fine_cylinder(od, thickness);
        translate([length,0,0]) fine_cylinder(od, thickness);
    }
}


// A cylinder with a bell end, which can be squeezed at that and to fit through a hole
// and will then expand and remain trapped through that hole. Good for a snap fit
// locating hole of some kind
module snap_peg(peg_dia, bellend_dia, length)
{
    bellend_length = bellend_dia/4;
    slice_width = peg_dia*0.3;
    slice_height = ((length*0.8)+bellend_length)*1;

    difference()
    {
        union()
        {
            fine_cylinder(peg_dia, length);
            translate([0,0,length])
                fine_cone(bellend_dia, peg_dia, bellend_length);
        }
        translate([-bellend_dia/2, -slice_width/2, length+bellend_length-slice_height])
            cube([bellend_dia, slice_width, slice_height]);
    }
}

// A vertical peg with a triangular nob on the end that you can use
// to press fit against the edge of something to attach it. For example, 
// to clip something to a PCB, or to push fit something into a hole that 
// you can't get to the back of like plaster board on a wall.
module edge_clip(height, width, thick, overhang, remove_top=0)
{
	angle = 30;
	clip_thick = thick+overhang;
	clip_height = clip_thick/tan(angle);
    difference()
    {
        translate([0,0,height*0.999])
            rotate([0,90,0])
            linear_extrude(height=width)
            polygon(points=[[0,0],[0,clip_thick],[-clip_height,0]]);
        translate([-width/2,-thick*2,height+(clip_height*(1-remove_top))])
            cube([width*2,thick*4,clip_height*2]);
    }
    cube([width,thick,height]);
}

// A high resolution cylinder with the negative x part chopped off
module half_cylinder(dia, length)
{
    difference()
    {
        fine_cylinder(dia, length);
        translate([-dia,-dia,-length/2])
            cube([dia,dia*2,length*2]);
    }
}


// A high resolution cylinder with the negative x and negative y parts chopped off
module quarter_cylinder(dia, length)
{
    difference()
    {
        half_cylinder(dia, length);
        translate([-0.001,-dia,-length/2])
            cube([dia,dia,length*2]);
    }
}

module quarter_curve(od, id, length, rounded=true)
{
    difference()
    {
        if(rounded==true)
        {
            quarter_cylinder(od, length);
        }
        else
        {
            cube([od/2,od/2,length]);
        }
        translate([0,0,-length/2])
            fine_cylinder(id, length*2);
    }
}