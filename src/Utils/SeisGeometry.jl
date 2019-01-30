"""
    SeisGeometry(in;<keyword arguments>)

Update headers with geometry information. Offsets and azimuths are calculated from source and receivers coordinates. 

# Arguments
* `in`: input filename

# Keyword arguments
* `ang=90`: inline direction measured in degrees CC from East
* `gamma=1`: vp/vs ratio for PS Asymptotic Conversion Point gathers (use gamma=1 for PP data)
* `osx=0`,`osy=0`,`ogx=0`,`ogy=0` : origin for source and receiver coordinate system
* `omx=0`,`omy=0`,`ohx=0`,`ohy=0`: origin for midpoint and offset coordinate system
* `oaz=0`,`oh=0` : origin for azimuth and offset coordinate system
* `dsx=1`,`dsy=1`,`dgx=1`,`dgy=1`: source and receiver step-size
* `dmx=1`,`dmy=1`,`dhx=1`,`dhy=1`: midpoint and offset step-size
* `dh=1`,`daz=1`: offset and azimuth step-size

# Outputs
the .seish file is updated with the following information:

* hx,hy,h,az,mx,my : calculated offset, azimuth and midpoint
* isx,isy,igx,igy,imx,imy,ihx,ihy,ih,iaz: calculated grid nodes for source and receiver position and midpoint, offset and azimuth.


*Credits: A. Stanton, 2017*

"""
function SeisGeometry(in; ang=90, gamma=1, osx=0, osy=0, ogx=0, ogy=0, omx=0,
                      omy=0, ohx=0, ohy=0, oh=0, oaz=0, dsx=1, dsy=1, dgx=1,
                      dgy=1, dmx=1, dmy=1, dhx=1, dhy=1, dh=1, daz=1)



    rad2deg = 180/pi
    deg2rad = pi/180
    gammainv = 1/gamma
    if (ang > 90)
	ang2=-deg2rad*(ang-90)
    else
	ang2=deg2rad*(90-ang)
    end

    filename = ParseHeaderName(in)
    stream = open(filename,"r+")
    nhead = 27
    nx = round(Int,filesize(stream)/(4*length(fieldnames(Header))))

    naz=convert(Int32,360/daz)

    for j=1:nx
	h = GrabHeader(stream,j)
	h.hx = h.gx - h.sx
	h.hy = h.gy - h.sy
	h.h = sqrt((h.hx^2) + (h.hy^2))
	h.az = rad2deg*atan2((h.gy-h.sy),(h.gx-h.sx))
	if (h.az < 0)
	    h.az += 360.0
	end
	h.mx = h.sx + h.hx/(1 + gammainv);
	h.my = h.sy + h.hy/(1 + gammainv);
	sx_rot = (h.sx-osx)*cos(ang2) - (h.sy-osy)*sin(ang2) + osx;
	sy_rot = (h.sx-osx)*sin(ang2) + (h.sy-osy)*cos(ang2) + osy;
	gx_rot = (h.gx-ogx)*cos(ang2) - (h.gy-ogy)*sin(ang2) + ogx;
	gy_rot = (h.gx-ogx)*sin(ang2) + (h.gy-ogy)*cos(ang2) + ogy;
	mx_rot = (h.mx-omx)*cos(ang2) - (h.my-omy)*sin(ang2) + omx;
	my_rot = (h.mx-omx)*sin(ang2) + (h.my-omy)*cos(ang2) + omy;
	hx_rot = (h.hx-ohx)*cos(ang2) - (h.hy-ohy)*sin(ang2) + ohx;
	hy_rot = (h.hx-ohx)*sin(ang2) + (h.hy-ohy)*cos(ang2) + ohy;
	h.isx = convert(Int32,round((sx_rot-osx)/dsx))
	h.isy = convert(Int32,round((sy_rot-osy)/dsy))
	h.igx = convert(Int32,round((gx_rot-ogx)/dgx))
	h.igy = convert(Int32,round((gy_rot-ogy)/dgy))
	h.imx = convert(Int32,round((mx_rot-omx)/dmx))
	h.imy = convert(Int32,round((my_rot-omy)/dmy))
	h.ihx = convert(Int32,round((hx_rot-ohx)/dhx))
	h.ihy = convert(Int32,round((hy_rot-ohy)/dhy))
	h.ih = convert(Int32,round((h.h-oh)/dh))

	h.iaz = convert(Int32,round((h.az-oaz)/daz))<naz ? convert(Int32,round((h.az-oaz)/daz)) : 0

	PutHeader(stream,h,j)
  end
  close(stream)

end