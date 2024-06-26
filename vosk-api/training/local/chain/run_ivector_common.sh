#!/bin/bash

set -euo pipefail

# This script is called from local/chain_${suffix}/run_tdnn.sh and
# local/chain_${suffix}/run_tdnn.sh (and may eventually be called by more
# scripts).  It contains the common feature preparation and
# iVector-related parts of the script.  See those scripts for examples
# of usage.

stage=0
train_set=train
gmm=tri3
suffix=""

. ./cmd.sh
. ./path.sh
. utils/parse_options.sh

gmm_dir=exp/${gmm}
ali_dir=exp/${gmm}_ali

if [ $stage -le 4 ]; then
  echo "$0: computing a subset of data to train the diagonal UBM."
  # We'll use about a quarter of the data.
  mkdir -p exp/chain${suffix}/diag_ubm
  temp_data_root=exp/chain${suffix}/diag_ubm

  num_utts_total=$(wc -l <data/${train_set}/utt2spk)
  num_utts=$[$num_utts_total/4]
  utils/data/subset_data_dir.sh data/${train_set} \
     $num_utts ${temp_data_root}/${train_set}_subset

  echo "$0: computing a PCA transform from the data."
  steps/online/nnet2/get_pca_transform.sh --cmd "$train_cmd" \
      --splice-opts "--left-context=3 --right-context=3" \
      --max-utts 10000 --subsample 2 \
       ${temp_data_root}/${train_set}_subset \
       exp/chain${suffix}/pca_transform

  echo "$0: training the diagonal UBM."
  # Use 512 Gaussians in the UBM.
  steps/online/nnet2/train_diag_ubm.sh --cmd "$train_cmd" --nj 10 \
    --num-frames 700000 \
    --num-threads 8 \
    ${temp_data_root}/${train_set}_subset 512 \
    exp/chain${suffix}/pca_transform exp/chain${suffix}/diag_ubm
fi

if [ $stage -le 5 ]; then
  # Train the iVector extractor.  Use all of the speed-perturbed data since iVector extractors
  # can be sensitive to the amount of data.  The script defaults to an iVector dimension of
  # 100.
  echo "$0: training the iVector extractor"
  steps/online/nnet2/train_ivector_extractor.sh --cmd "$train_cmd" --nj 2 \
     --ivector-dim 40 \
     data/${train_set} exp/chain${suffix}/diag_ubm \
     exp/chain${suffix}/extractor || exit 1;
fi


if [ $stage -le 6 ]; then
  # We extract iVectors on the speed-perturbed training data after combining
  # short segments, which will be what we train the system on.  With
  # --utts-per-spk-max 2, the script pairs the utterances into twos, and treats
  # each of these pairs as one speaker; this gives more diversity in iVectors..
  # Note that these are extracted 'online'.

  # note, we don't encode the 'max2' in the name of the ivectordir even though
  # that's the data we extract the ivectors from, as it's still going to be
  # valid for the non-'max2' data, the utterance list is the same.

  ivectordir=exp/chain${suffix}/ivectors_${train_set}

  # having a larger number of speakers is helpful for generalization, and to
  # handle per-utterance decoding well (iVector starts at zero).
  temp_data_root=${ivectordir}
  utils/data/modify_speaker_info.sh --utts-per-spk-max 2 \
    data/${train_set} ${temp_data_root}/${train_set}_max2

  steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj 10 \
    ${temp_data_root}/${train_set}_max2 \
    exp/chain${suffix}/extractor $ivectordir
fi

exit 0
