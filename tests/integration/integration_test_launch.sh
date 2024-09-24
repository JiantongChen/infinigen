# Environment Variables for Opting In/Out
RUN_INDOOR=${RUN_INDOOR:-1}
RUN_NATURE=${RUN_NATURE:-1}
RUN_INDOOR_ASSETS=${RUN_INDOOR_ASSETS:-1}
RUN_NATURE_ASSETS=${RUN_INDOOR_MATERIALS:-1}

# Version Info
INFINIGEN_VERSION=$(python -c "import infinigen; print(infinigen.__version__)")
COMMIT_HASH=$(git rev-parse HEAD | cut -c 1-6) 
DATE=$(date '+%Y-%m-%d')
JOBTAG="${DATE}_ifg-int"
BRANCH=$(git rev-parse --abbrev-ref HEAD | sed 's/_/-/g')
VERSION_STRING="${DATE}_${INFINIGEN_VERSION}_${BRANCH}_${COMMIT_HASH}_${USER}"
OUTPUT_PATH=/n/fs/pvl-renders/integration_test/runs/

mkdir -p $OUTPUT_PATH
OUTPUT_PATH=$OUTPUT_PATH/$VERSION_STRING

NODECONF="\"node004,node005,node006,node008,node901,node902,node906,node907,node908,node909,node910,node911,node912,node913,node914\""

# Run Indoor Scene Generation
if [ "$RUN_INDOOR" -eq 1 ]; then
    for indoor_type in DiningRoom Bathroom Bedroom Kitchen LivingRoom; do
        python -m infinigen.datagen.manage_jobs --output_folder $OUTPUT_PATH/${JOBTAG}_scene_indoor_$indoor_type \
        --num_scenes 3 --cleanup big_files --configs singleroom --overwrite \
        --pipeline_configs slurm monocular indoor_background_configs.gin \
        --pipeline_overrides get_cmd.driver_script=infinigen_examples.generate_indoors sample_scene_spec.seed_range=[0,100] slurm_submit_cmd.slurm_nodelist=$NODECONF \
        --overrides compose_indoors.terrain_enabled=True restrict_solving.restrict_parent_rooms=\[\"$indoor_type\"\] &
    done
fi

# Run Nature Scene Generation
if [ "$RUN_NATURE" -eq 1 ]; then
    for nature_type in arctic canyon cave coast coral_reef desert forest kelp_forest mountain plain river snowy_mountain under_water; do
        python -m infinigen.datagen.manage_jobs --output_folder $OUTPUT_PATH/${JOBTAG}_scene_nature_$nature_type \
        --num_scenes 3 --cleanup big_files --overwrite \
        --configs $nature_type.gin \
        --pipeline_configs slurm monocular \
        --pipeline_overrides sample_scene_spec.seed_range=[0,100] slurm_submit_cmd.slurm_nodelist=$NODECONF &
    done
fi

# Run Indoor Meshes Generation
if [ "$RUN_INDOOR_ASSETS" -eq 1 ]; then
    python -m infinigen_examples.generate_individual_assets \
    -f tests/assets/list_indoor_meshes.txt --output_folder $OUTPUT_PATH/${JOBTAG}_asset_indoor_meshes \
    --overrides mapfunc.slurm_nodelist=$NODECONF \
    --slurm --n_workers 100 -n 3 &

    python -m infinigen_examples.generate_individual_assets \
    -f tests/assets/list_indoor_materials.txt --output_folder $OUTPUT_PATH/${JOBTAG}_asset_indoor_materials \
    --overrides mapfunc.slurm_nodelist=$NODECONF \
    --slurm --n_workers 100 -n 3 &
fi

# Run Nature Meshes Generation
if [ "$RUN_NATURE_ASSETS" -eq 1 ]; then
    python -m infinigen_examples.generate_individual_assets \
    -f tests/assets/list_nature_meshes.txt --output_folder $OUTPUT_PATH/${JOBTAG}_asset_nature_meshes \
    --overrides mapfunc.slurm_nodelist=$NODECONF \
    --slurm --n_workers 100 -n 3 &

    python -m infinigen_examples.generate_individual_assets \
    -f tests/assets/list_nature_materials.txt --output_folder $OUTPUT_PATH/${JOBTAG}_asset_nature_materials \
    --overrides mapfunc.slurm_nodelist=$NODECONF \
    --slurm --n_workers 100 -n 3 &
fi

# Wait for all background processes to finish
wait