<h1 align="center">multi lap</h1>

<p align="center">
  Segments white matter bundles in a target tractogram by solving multiple Linear Assignment Problems (multi-LAP) against example bundles from other subjects, with optional SLR registration, and outputs a WMC classification.
</p>

<p align="center">
  <a href="https://github.com/brainlife/abcd-spec"><img src="https://img.shields.io/badge/ABCD_Spec-v1.1-green.svg" alt="ABCD Spec v1.1"></a>
  <a href="https://doi.org/10.25663/brainlife.app.209"><img src="https://img.shields.io/badge/Brainlife-brainlife.app.209-blue.svg" alt="Run on brainlife.io"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-see_LICENSE-lightgrey.svg" alt="License"></a>
</p>

## At a glance

<!-- brainlife-app:begin (generated from the App manifest; edit the manifest, not this block) -->

> **Segments white matter bundles in a target tractogram by solving multiple Linear Assignment Problems (multi-LAP) against example bundles from other subjects, with optional SLR registration, and outputs a WMC classification.**

Supervised, example-based bundle segmentation: for each bundle of interest it takes the corresponding bundles of several example subjects, optionally registers their tractograms to the target with streamline-based linear registration (SLR), and assigns target streamlines by solving linear assignment problems in a dissimilarity space. Use it to extract named bundles (e.g. AFQ or WMA tracts) in a new subject when segmented examples exist. It needs the target tractogram and T1, plus, for each example subject, its tractogram, T1 and WMC segmentation in the same order and with matching subject IDs.

| | |
|---|---|
| **Inputs** | `neuro/track/tck` ×2 · `neuro/anat/t1w` ×2 · `neuro/wmc` |
| **Outputs** | `neuro/wmc` |
| **Container** | `brainlife/dipy:0.16.0` |
| **Resources** | 16 CPUs · 31 GB memory · 10 h walltime |
| **Run it** | [doi.org/10.25663/brainlife.app.209](https://doi.org/10.25663/brainlife.app.209) |

#### Inputs

| Input | Datatype | Required | Description |
|---|---|---|---|
| `0` | `neuro/track/tck` | yes | Tractogram (.tck) of the target subject to segment. |
| `1` | `neuro/anat/t1w` (acpc_aligned) | yes | ACPC-aligned T1 of the target subject, used to convert its tractogram to .trk. |
| `2` | `neuro/wmc` | yes | WMC segmentations of the example subjects (multi), derived from their example tractograms. One per example subject, in the same order as the example tractograms and T1s; subject IDs must match. |
| `3` | `neuro/track/tck` | yes | Tractograms (.tck) of the example subjects (multi). |
| `4` | `neuro/anat/t1w` (acpc_aligned) | yes | ACPC-aligned T1s of the example subjects (multi). |

#### Outputs

| Output | Datatype | Description |
|---|---|---|
| `output_wmc` | `neuro/wmc` | WMC classification of the target tractogram with the segmented bundles of interest. |

<details>
<summary><b>Parameters</b> (4)</summary>

| Parameter | Type | Default | Description |
|---|---|---|---|
| `k` | number | `2000` | value for k-NN to compute the superset |
| `step_size` | number | `0.625` | step size for resampling |
| `slr` | boolean | `true` | If false, assuming subjects already co-registered in the same space |
| `tractID_list` | string |  | ID list of the bundles of interest, separated by commas |

</details>

<!-- brainlife-app:end -->

## Versions on brainlife.io

This repository hosts several Apps, each built from its own branch.

| App | Branch | Run it | Status |
|---|---|---|---|
| multi-LAP | [`3.1`](https://github.com/giulia-berto/app-multi-lap/tree/3.1) | [doi:10.25663/brainlife.app.209](https://doi.org/10.25663/brainlife.app.209) | current |
| multi-LAP and multi-NN (deprecated) | [`1.0`](https://github.com/giulia-berto/app-multi-lap/tree/1.0) | [doi:10.25663/brainlife.app.174](https://doi.org/10.25663/brainlife.app.174) | deprecated |

## Running the App

### On brainlife.io

Open the App at [doi.org/10.25663/brainlife.app.209](https://doi.org/10.25663/brainlife.app.209), choose `neuro/track/tck`, `neuro/anat/t1w`, `neuro/wmc`, `neuro/track/tck`, `neuro/anat/t1w` from your project, set the parameters and press **Execute**. The results are saved to your project as `neuro/wmc`.

### Locally

You need [Singularity/Apptainer](https://apptainer.org/) (the App runs in `brainlife/dipy:0.16.0`), [`jq`](https://jqlang.github.io/jq/).

1. Clone this repository and check out the App's branch (`git checkout 3.1`).
2. Create `config.json` with the paths to your inputs and the parameters:

   ```json
   {
       "tractogram_static": "/path/to/0/tractogram_static",
       "t1_static": "/path/to/1/t1_static",
       "segmentations": "/path/to/2/segmentations",
       "tracts": "/path/to/2/tracts",
       "tractograms_moving": "/path/to/3/tractograms_moving",
       "t1s_moving": "/path/to/4/t1s_moving",
       "k": 2000,
       "step_size": 0.625,
       "slr": true,
       "tractID_list": ""
   }
   ```

3. Run `./main`.

## Troubleshooting

- **Inputs subject id incorrectly inserted. Check them again.**: Select example inputs in the same subject order and use target tractogram and T1 from one subject.

## On [Brainlife.io](http://brainlife.io/)

You can submit this App online at https://doi.org/10.25663/brainlife.app.209 via the “Execute” tab.

Inputs: \
To perform the bundle segmentation, you need two key elements: (i) the tractogram of the (target) subject you want to extract the bundle from and (ii) the wmc segmentations of multiple (example) subjects you want to learn from. Moreover, you have to provide the anatomical T1s and the tractograms of the (example) subjects (which are used to apply an initial Streamline Linear Registration (SLR) between tractograms). The wmc segmentation files you have to provide as examples should be obtained using the AFQ algorithm (https://doi.org/10.25663/bl.app.13) or the the WMA algorithm (https://doi.org/10.25663/bl.app.41). You can choose the bundle to be segmented (one at the time) by providing the id related to the bundle to be segmented, from 1 to 20 if providing AFQ segmentations, and from 1 to 78 if providing WMA segmentations. 

Output: \
You will get the wmc segmentation of the bundle(s) of interest in the target subject.

#### Branch 1.0:
It also performs Nearest Neighbor (NN, or multi-NN) segmentation for comparison. This branch is associated with the App https://doi.org/10.25663/brainlife.app.174 (deprecated).

#### Branch 2.0:
As branch 2.0, but with trk input (deprecated).

#### Branch 3.0:
This branch implements the same functionalities of the branch 1.0 but with the following changes: 
- uses the new wmc input 
- SLR registration is optional
- can run multiple bundles at the same time 

You may provide as examples AFQ segmentations obtained by the app https://doi.org/10.25663/brainlife.app.207 or WMA segmentations obtained by the app https://doi.org/10.25663/brainlife.app.188.

#### Branch 3.1:
As branch 3.0 with some small enhancements.

## Citing

If you use this App, please cite it, the software it builds on and brainlife.io:

- multi-LAP. brainlife.io App. [doi:10.25663/brainlife.app.209](https://doi.org/10.25663/brainlife.app.209)
- Sharmin N, Olivetti E, Avesani P. White Matter Tract Segmentation as Multiple Linear Assignment Problems. Front Neurosci (2018). [doi:10.3389/fnins.2017.00754](https://doi.org/10.3389/fnins.2017.00754)
- Garyfallidis et al. Dipy, a library for the analysis of diffusion MRI data. *Frontiers in Neuroinformatics* 8 (2014). [doi:10.3389/fninf.2014.00008](https://doi.org/10.3389/fninf.2014.00008)
- Hayashi S, Caron BA, Heinsfeld AS, et al. brainlife.io: a decentralized and open-source cloud platform to support neuroscience research. *Nature Methods* 21:809–813 (2024). [doi:10.1038/s41592-024-02237-2](https://doi.org/10.1038/s41592-024-02237-2)
- Avesani P, McPherson B, Hayashi S, et al. The open diffusion data derivatives, brain data upcycling via integrated publishing of derivatives and reproducible open cloud services. *Scientific Data* 6:69 (2019). [doi:10.1038/s41597-019-0073-y](https://doi.org/10.1038/s41597-019-0073-y)

## Authors

- Giulia Bertò

**Contributors**

- Emanuele Olivetti

## Funding

[![Wellcome-226486/Z/22/Z](https://img.shields.io/badge/Wellcome-226486%2FZ%2F22%2FZ-purple.svg)](https://wellcome.org/)
[![NIH-NINDS-U24NS140384](https://img.shields.io/badge/NIH_NINDS-U24NS140384-green.svg)](https://reporter.nih.gov/project-details/11261037)
[![NIH-NINDS-UM1NS132207](https://img.shields.io/badge/NIH_NINDS-UM1NS132207-green.svg)](https://reporter.nih.gov/project-details/11411328)
[![NIH-NIBIB-R01EB029272](https://img.shields.io/badge/NIH_NIBIB-R01EB029272-green.svg)](https://reporter.nih.gov/project-details/10262925)
[![NIH-NIBIB-R01EB030896](https://img.shields.io/badge/NIH_NIBIB-R01EB030896-green.svg)](https://reporter.nih.gov/project-details/10428625)
[![NIH-NIMH-R01MH126699](https://img.shields.io/badge/NIH_NIMH-R01MH126699-green.svg)](https://reporter.nih.gov/project-details/10460628)
[![NIH-NIDCD-R01DC020088](https://img.shields.io/badge/NIH_NIDCD-R01DC020088-green.svg)](https://reporter.nih.gov/project-details/11140284)
[![NSF-BCS-1734853](https://img.shields.io/badge/NSF_BCS-1734853-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1734853)
[![NSF-BCS-2203524](https://img.shields.io/badge/NSF_BCS-2203524-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2203524)
[![NSF-IIS-1636893](https://img.shields.io/badge/NSF_IIS-1636893-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1636893)
[![NSF-OAC-2148729](https://img.shields.io/badge/NSF_OAC-2148729-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148729)
[![NSF-IIS-1912270](https://img.shields.io/badge/NSF_IIS-1912270-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1912270)
[![NSF-IIS-2148700](https://img.shields.io/badge/NSF_IIS-2148700-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=2148700)
[![NSF-OAC-1916518](https://img.shields.io/badge/NSF_OAC-1916518-blue.svg)](https://www.nsf.gov/awardsearch/showAward?AWD_ID=1916518)

<sub>brainlife.io, which runs this App, is publicly funded by Wellcome, the U.S. National Institutes of Health and the U.S. National Science Foundation; acknowledging that support helps keep it running.</sub>

## License

See [LICENSE](LICENSE).
