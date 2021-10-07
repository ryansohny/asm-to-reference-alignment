table gene_conversion
"Windows with evidence of gene conversion"
(
string  chrom;		"Chromosome for original alignment"
uint    chromStart;	"Start position of original alignment"
uint    chromEnd;	"End position of original alignment"
float    perID_by_all;		"Percent identity of alignment at original alignment location"
uint    mismatches;		"mismatches at original alignment"
string  donorChrom;		"Chromosome for donor alignment"
uint    donorStart;	"Start position of donor alignment"
uint    donorEnd;	"End position of donor alignment"
float    donor_perID_by_all;		"Percent identity of alignment at donor location"
uint    donorMismatches;		"mismatches at donor alignment"
)