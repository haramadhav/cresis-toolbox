% Permittivity of free-space (F*m^-1), http://en.wikipedia.org/wiki/Permittivity
e0 = 8.8541878176e-12;
% Permeability of free-space (N*A^-2), http://en.wikipedia.org/wiki/Permeability_%28electromagnetism%29
u0 = 4e-7*pi;
% Speed of light in free-space
c = 1/sqrt(e0*u0);
% Boltzmann's constant (J * K^-1 * Hz^-1), http://en.wikipedia.org/wiki/Boltzmann_constant
BoltzmannConst = 1.380650524e-23;
% Earth Radius (m) from WGS-84 ellipsoid (larger: equatorial radius,
% smaller: polar radius)
earthRadius = 0.5*(6378137+6356752.31424518);
% Earth mass (kg), http://en.wikipedia.org/wiki/Mass_of_the_Earth
earthMass = 5.9742e24;
% Gravitational constant (N * m^2 * kg^-2), http://en.wikipedia.org/wiki/Gravity_constant
G = 6.6742e-11;
% Note: G*earthMass = 398600.5 km^3/s^2 according to satellite orbit book,
% which does match the values above.
GearthMassProd = 398600.5e9;

% WGS84 ellipsoid parameters [semimajor sqrt(e2)]
WGS84.semimajor = 6378137;
WGS84.semiminor = 6356752.314245;
WGS84.flattening = 298.257223563;
WGS84.eccentricity = sqrt(0.00669437999013);
WGS84.ellipsoid = [WGS84.semimajor WGS84.eccentricity];

% Basic ice properties
er_ice = 3.15;
% er_ice = 1;

% Arctic North Polar Stereographic NSIDC
arctic_proj.Filename='P:\GIS_data\greenland\Landsat-7\Greenland_natural_90m.tif';
arctic_proj.FileModDate='22-Sep-2011 13:51:54';
arctic_proj.FileSize=reshape([33401598],[1  1]);
arctic_proj.Format='tif';
arctic_proj.Height=reshape([29607],[1  1]);
arctic_proj.Width=reshape([17680],[1  1]);
arctic_proj.BitDepth=reshape([8],[1  1]);
arctic_proj.ColorType='unknown';
arctic_proj.ModelType='ModelTypeProjected';
arctic_proj.PCS='WGS 84 / NSIDC Sea Ice Polar Stereographic North';
arctic_proj.Projection='US NSIDC Sea Ice polar stereographic north';
arctic_proj.MapSys='';
arctic_proj.Zone=[];
arctic_proj.CTProjection='CT_PolarStereographic';
arctic_proj.ProjParm=reshape([70 -45   0   0   1   0   0],[7  1]);
arctic_proj.ProjParmId={'ProjNatOriginLatGeoKey';'ProjStraightVertPoleLongGeoKey';'Unknown-0';'Unknown-0';'ProjScaleAtNatOriginGeoKey';'ProjFalseEastingGeoKey';'ProjFalseNorthingGeoKey';};
arctic_proj.GCS='WGS 84';
arctic_proj.Datum='World Geodetic System 1984';
arctic_proj.Ellipsoid='WGS 84';
arctic_proj.SemiMajor=reshape([6378137],[1  1]);
arctic_proj.SemiMinor=reshape([6356752.3142],[1  1]);
arctic_proj.PM='Greenwich';
arctic_proj.PMLongToGreenwich=reshape([0],[1  1]);
arctic_proj.UOMLength='metre';
arctic_proj.UOMLengthInMeters=reshape([1],[1  1]);
arctic_proj.UOMAngle='degree';
arctic_proj.UOMAngleInDegrees=reshape([1],[1  1]);
arctic_proj.TiePoints.ImagePoints.Row=reshape([0.5],[1  1]);
arctic_proj.TiePoints.ImagePoints.Col=reshape([0.5],[1  1]);
arctic_proj.TiePoints.WorldPoints.X=reshape([-693482.9938],[1  1]);
arctic_proj.TiePoints.WorldPoints.Y=reshape([-774973.5364],[1  1]);
arctic_proj.PixelScale=reshape([90  90   1],[3  1]);
arctic_proj.SpatialRef = maprasterref('XLimWorld',reshape([-693482.9938      897717.0062],[1  2]),'YLimWorld',reshape([-3439603.5364      -774973.5364],[1  2]),...
  'RasterSize',reshape([29607  17680],[1  2]),'RasterInterpretation','cells','ColumnsStartFrom','north','RowsStartFrom','west');
arctic_proj.RefMatrix=reshape([0               90     -693527.9938              -90                0     -774928.5364],[3  2]);
arctic_proj.BoundingBox=reshape([-693482.99377      897717.00623     -3439603.5364      -774973.5364],[2  2]);
arctic_proj.CornerCoords.X=reshape([-693482.9938      897717.0062      897717.0062     -693482.9938],[1  4]);
arctic_proj.CornerCoords.Y=reshape([-774973.5364      -774973.5364     -3439603.5364     -3439603.5364],[1  4]);
arctic_proj.CornerCoords.Row=reshape([0.5             0.5         29607.5         29607.5],[1  4]);
arctic_proj.CornerCoords.Col=reshape([0.5         17680.5         17680.5             0.5],[1  4]);
arctic_proj.CornerCoords.Lat=reshape([80.4214       79.084      58.0087      58.4027],[1  4]);
arctic_proj.CornerCoords.Lon=reshape([-86.8237      4.19689     -30.3724      -56.399],[1  4]);
arctic_proj.GeoTIFFCodes.Model=reshape([1],[1  1]);
arctic_proj.GeoTIFFCodes.PCS=reshape([3413],[1  1]);
arctic_proj.GeoTIFFCodes.GCS=reshape([4326],[1  1]);
arctic_proj.GeoTIFFCodes.UOMLength=reshape([9001],[1  1]);
arctic_proj.GeoTIFFCodes.UOMAngle=reshape([9122],[1  1]);
arctic_proj.GeoTIFFCodes.Datum=reshape([6326],[1  1]);
arctic_proj.GeoTIFFCodes.PM=reshape([8901],[1  1]);
arctic_proj.GeoTIFFCodes.Ellipsoid=reshape([7030],[1  1]);
arctic_proj.GeoTIFFCodes.ProjCode=reshape([19865],[1  1]);
arctic_proj.GeoTIFFCodes.Projection=reshape([9829],[1  1]);
arctic_proj.GeoTIFFCodes.CTProjection=reshape([15],[1  1]);
arctic_proj.GeoTIFFCodes.MapSys=reshape([32767],[1  1]);
arctic_proj.GeoTIFFCodes.ProjParmId=reshape([3081],[1  1]);
arctic_proj.GeoTIFFCodes.ProjParmId=reshape([3095],[1  1]);
arctic_proj.GeoTIFFCodes.ProjParmId=reshape([0],[1  1]);
arctic_proj.GeoTIFFCodes.ProjParmId=reshape([0],[1  1]);
arctic_proj.GeoTIFFCodes.ProjParmId=reshape([3092],[1  1]);
arctic_proj.GeoTIFFCodes.ProjParmId=reshape([3082],[1  1]);
arctic_proj.GeoTIFFCodes.ProjParmId=reshape([3083],[1  1]);
arctic_proj.GeoTIFFTags.ModelPixelScaleTag=reshape([90  90   1],[1  3]);
arctic_proj.GeoTIFFTags.ModelTiepointTag=reshape([0                0                0     -693482.9938     -774973.5364                0],[1  6]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GTModelTypeGeoKey=reshape([1],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GTRasterTypeGeoKey=reshape([1],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GeographicTypeGeoKey=reshape([4326],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GeogAngularUnitsGeoKey=reshape([9102],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GeogSemiMajorAxisGeoKey=reshape([6378137],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GeogSemiMinorAxisGeoKey=reshape([6356752.3142],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GeogInvFlatteningGeoKey=reshape([298.2572],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjectedCSTypeGeoKey=reshape([3413],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjCoordTransGeoKey=reshape([15],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjLinearUnitsGeoKey=reshape([9001],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjStdParallel1GeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjStdParallel2GeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjNatOriginLongGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjNatOriginLatGeoKey=reshape([70],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjFalseEastingGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjFalseNorthingGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjFalseOriginLongGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjFalseOriginLatGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjFalseOriginEastingGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjFalseOriginNorthingGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjCenterLongGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjCenterLatGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjCenterEastingGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjCenterNorthingGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjScaleAtNatOriginGeoKey=reshape([1],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjAzimuthAngleGeoKey=reshape([0],[1  1]);
arctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjStraightVertPoleLongGeoKey=reshape([-45],[1  1]);
arctic_proj.GeoTIFFTags.GeoDoubleParamsTag=reshape([6378137      6356752.3142      298.25722356                 0                 0                 0                70                 0                 0                 0                 0                 0                 0                 0                 0                 0                 0                 1                 0               -45],[1  20]);

% Antarctic South Polar Stereographic NSIDC
antarctic_proj.Filename='P:\GIS_data\antarctica\Landsat-7\Antarctica_LIMA.tif';
antarctic_proj.FileModDate='14-Jun-2012 13:21:25';
antarctic_proj.FileSize=reshape([333931959],[1  1]);
antarctic_proj.Format='tif';
antarctic_proj.FormatVersion=reshape([],[0  0]);
antarctic_proj.Height=reshape([19404],[1  1]);
antarctic_proj.Width=reshape([22842],[1  1]);
antarctic_proj.BitDepth=reshape([8],[1  1]);
antarctic_proj.ColorType='truecolor';
antarctic_proj.ModelType='ModelTypeProjected';
antarctic_proj.PCS='';
antarctic_proj.Projection='';
antarctic_proj.MapSys='';
antarctic_proj.Zone=reshape([],[0  0]);
antarctic_proj.CTProjection='CT_PolarStereographic';
antarctic_proj.ProjParm=reshape([-71   0   0   0   1   0   0],[7  1]);
antarctic_proj.ProjParmId={'ProjNatOriginLatGeoKey';'ProjStraightVertPoleLongGeoKey';'Unknown-0';'Unknown-0';'ProjScaleAtNatOriginGeoKey';'ProjFalseEastingGeoKey';'ProjFalseNorthingGeoKey';};
antarctic_proj.GCS='WGS 84';
antarctic_proj.Datum='World Geodetic System 1984';
antarctic_proj.Ellipsoid='WGS 84';
antarctic_proj.SemiMajor=reshape([6378137],[1  1]);
antarctic_proj.SemiMinor=reshape([6356752.3142],[1  1]);
antarctic_proj.PM='Greenwich';
antarctic_proj.PMLongToGreenwich=reshape([0],[1  1]);
antarctic_proj.UOMLength='metre';
antarctic_proj.UOMLengthInMeters=reshape([1],[1  1]);
antarctic_proj.UOMAngle='degree';
antarctic_proj.UOMAngleInDegrees=reshape([1],[1  1]);
antarctic_proj.TiePoints.ImagePoints.Row=reshape([0.5],[1  1]);
antarctic_proj.TiePoints.ImagePoints.Col=reshape([0.5],[1  1]);
antarctic_proj.TiePoints.WorldPoints.X=reshape([-2668274.9891],[1  1]);
antarctic_proj.TiePoints.WorldPoints.Y=reshape([2362334.97],[1  1]);
antarctic_proj.PixelScale=reshape([240           240             0],[3  1]);
antarctic_proj.SpatialRef = maprasterref('XLimWorld',reshape([-2668274.9891      2813805.0226],[1  2]),'YLimWorld',reshape([-2294625.04        2362334.97],[1  2]),...
  'RasterSize',reshape([19404  22842],[1  2]),'RasterInterpretation','cells','ColumnsStartFrom','north','RowsStartFrom','west');
antarctic_proj.RefMatrix=reshape([0      240.00000052     -2668394.9891     -240.00000052                 0        2362454.97],[3  2]);
antarctic_proj.BoundingBox=reshape([-2668274.9891      2813805.0226       -2294625.04        2362334.97],[2  2]);
antarctic_proj.CornerCoords.X=reshape([-2668274.9891      2813805.0226      2813805.0226     -2668274.9891],[1  4]);
antarctic_proj.CornerCoords.Y=reshape([2362334.97        2362334.97       -2294625.04       -2294625.04],[1  4]);
antarctic_proj.CornerCoords.Row=reshape([0.5             0.5         19404.5         19404.5],[1  4]);
antarctic_proj.CornerCoords.Col=reshape([0.5         22842.5         22842.5             0.5],[1  4]);
antarctic_proj.CornerCoords.Lat=reshape([-58.0236     -57.0855     -57.4523     -58.4037],[1  4]);
antarctic_proj.CornerCoords.Lon=reshape([-48.4802       49.9848      129.1968     -130.6944],[1  4]);
antarctic_proj.GeoTIFFCodes.Model=reshape([1],[1  1]);
antarctic_proj.GeoTIFFCodes.PCS=reshape([32767],[1  1]);
antarctic_proj.GeoTIFFCodes.GCS=reshape([4326],[1  1]);
antarctic_proj.GeoTIFFCodes.UOMLength=reshape([9001],[1  1]);
antarctic_proj.GeoTIFFCodes.UOMAngle=reshape([9122],[1  1]);
antarctic_proj.GeoTIFFCodes.Datum=reshape([6326],[1  1]);
antarctic_proj.GeoTIFFCodes.PM=reshape([8901],[1  1]);
antarctic_proj.GeoTIFFCodes.Ellipsoid=reshape([7030],[1  1]);
antarctic_proj.GeoTIFFCodes.ProjCode=reshape([32767],[1  1]);
antarctic_proj.GeoTIFFCodes.Projection=reshape([32767],[1  1]);
antarctic_proj.GeoTIFFCodes.CTProjection=reshape([15],[1  1]);
antarctic_proj.GeoTIFFCodes.MapSys=reshape([32767],[1  1]);
antarctic_proj.GeoTIFFCodes.ProjParmId=reshape([3081],[1  1]);
antarctic_proj.GeoTIFFCodes.ProjParmId=reshape([3095],[1  1]);
antarctic_proj.GeoTIFFCodes.ProjParmId=reshape([0],[1  1]);
antarctic_proj.GeoTIFFCodes.ProjParmId=reshape([0],[1  1]);
antarctic_proj.GeoTIFFCodes.ProjParmId=reshape([3092],[1  1]);
antarctic_proj.GeoTIFFCodes.ProjParmId=reshape([3082],[1  1]);
antarctic_proj.GeoTIFFCodes.ProjParmId=reshape([3083],[1  1]);
antarctic_proj.GeoTIFFTags.ModelPixelScaleTag=reshape([240           240             0],[1  3]);
antarctic_proj.GeoTIFFTags.ModelTiepointTag=reshape([0                 0                 0     -2668274.9891        2362334.97                 0],[1  6]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GTModelTypeGeoKey=reshape([1],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GTRasterTypeGeoKey=reshape([1],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GTCitationGeoKey='PCS Name = Polar_Stereographic';
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GeographicTypeGeoKey=reshape([4326],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GeogCitationGeoKey='GCS_WGS_1984';
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GeogAngularUnitsGeoKey=reshape([9102],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GeogSemiMajorAxisGeoKey=reshape([6378137],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.GeogInvFlatteningGeoKey=reshape([298.2572],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjectedCSTypeGeoKey=reshape([32767],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjectionGeoKey=reshape([32767],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjCoordTransGeoKey=reshape([15],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjLinearUnitsGeoKey=reshape([9001],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjNatOriginLatGeoKey=reshape([-71],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjFalseEastingGeoKey=reshape([0],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjFalseNorthingGeoKey=reshape([0],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjScaleAtNatOriginGeoKey=reshape([1],[1  1]);
antarctic_proj.GeoTIFFTags.GeoKeyDirectoryTag.ProjStraightVertPoleLongGeoKey=reshape([0],[1  1]);
antarctic_proj.GeoTIFFTags.GeoDoubleParamsTag=reshape([-71                 0                 1                 0                 0      298.25722356           6378137],[1  7]);
antarctic_proj.GeoTIFFTags.GeoAsciiParamsTag='PCS Name = Polar_Stereographic|GCS_WGS_1984|';