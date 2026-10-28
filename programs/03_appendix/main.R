# Appendix results. Uses the estimates saved by programs/02_analysis/estimates.R.

if (!exists("CONFIG_LOADED")) source("programs/config.R")

source(file.path(programs_dir, "03_appendix", "tableA1.R"))   # Table A1: robustness checks
source(file.path(programs_dir, "03_appendix", "tableA2.R"))   # Table A2: regulation records
source(file.path(programs_dir, "03_appendix", "tableA3.R"))   # Table A3: counties regulating before announcement
source(file.path(programs_dir, "03_appendix", "figureA1.R"))  # Figure A1: announcements by month
source(file.path(programs_dir, "03_appendix", "figureA2.R"))  # Figure A2: raw share with a rule, event time
source(file.path(programs_dir, "03_appendix", "figureA3.R"))  # Figure A3: event studies, all specifications
source(file.path(programs_dir, "03_appendix", "figureA4.R"))  # Figure A4: counties observed by months since announcement
