function get_atlas_values(atlas_file, out_file)

atlas = load_untouch_nii(atlas_file);
atlas_img = atlas.img;

atlas_values = unique(atlas_img);
atlas_values(1) = [];

dlmwrite(out_file, atlas_values)

end
