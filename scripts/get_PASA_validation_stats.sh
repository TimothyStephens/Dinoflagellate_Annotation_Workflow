# This scripts is to get stats about validation of transcripts mapping at PASA step.
# One the PASA job finished, copy this script to PASA working directory and run:
# bash get_PASA_validation_stats.sh

NUM_MAPPED_TRAN=$(grep -v "#" alignment.validations.output | cut -f2 |sort|uniq|wc -l)

awk '{if ($9 == "OK") print $2}' alignment.validations.output |sort|uniq > transcript_passed.id

NUM_TRAN_PASS=$(cat transcript_passed.id|wc -l)

NUM_TRAN_FAIL=$(($NUM_MAPPED_TRAN-$NUM_TRAN_PASS))

grep -v "#" alignment.validations.output|grep -v -F -f transcript_passed.id  > alignment.validations.fail

awk '{if($11>=95 && $12>=75) print $0}' alignment.validations.fail > alignment.validations.fail_but_good_mapping

NUM_TRAN_FAIL_BUT_GOOD_MAPPING=$(cat alignment.validations.fail_but_good_mapping|wc -l)

NUM_TRAN_FAIL_BECAUSE_OF_MAPPING=$(($NUM_TRAN_FAIL-$NUM_TRAN_FAIL_BUT_GOOD_MAPPING))

NUM_TRAN_FAIL_BECAUSE_OF_SPLICE_SITE=$(grep -F "Splice site validations failed" alignment.validations.fail_but_good_mapping|cut -f2|sort|uniq|wc -l)

echo "num_of_mapped_transcripts:" $NUM_MAPPED_TRAN
echo "transcripts_Passed_validation:" $NUM_TRAN_PASS
echo "transcripts_failed_validation:" $NUM_TRAN_FAIL
echo "within failed transcripts:"
echo "failed_because_of_low_mapping_Quality (identity>=95%, query_cover>=75% required):" $NUM_TRAN_FAIL_BECAUSE_OF_MAPPING
echo "failed_because_of_splice_site (not G[TCA]-AG):" $NUM_TRAN_FAIL_BECAUSE_OF_SPLICE_SITE
