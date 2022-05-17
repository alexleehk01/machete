#!/bin/bash
# add tag to tf aws cf resource

# get all tf files
tf_files=$(find ./ -name '*.tf' | grep -v 'tmp' | grep -v 'service') # temp exclude service folder

for tf_file in $tf_files; do
  add_tag_count=0
  rm -rf tmp
  mkdir tmp
  pushd tmp >/dev/null
  csplit -z -s -f '' -b %03d.tf ../$tf_file '/^[a-z]* "/' '{*}'
  popd >/dev/null
  for tmp_file in tmp/*; do
    grep_cf=$(cat $tmp_file | grep '^resource "aws_cloudfront_distribution"')
    if [[ ! -z $grep_cf ]]; then
      grep_tags=$(cat $tmp_file | grep '^\s*tags = {')
      echo $tf_file
      if [[ -z $grep_tags ]]; then
        echo '! tag block missing'
        cat $tmp_file | grep -v '^}' >tmp_file_updated
        cat <<EOF >>tmp_file_updated

  tags = {
    ManagedBy = "Terraform"
  }
}

EOF
        rm -f $tmp_file
        mv -f tmp_file_updated $tmp_file
        ((add_tag_count++))
        echo '✔ added tag block and tf tag'
      else
        grep_tf_tag=$(cat $tmp_file | grep '^\s*ManagedBy\s*= "Terraform"')
        if [[ -z $grep_tf_tag ]]; then
          echo '! tf tag missing'
          sed -i 's/tags = {/tags = {\n    ManagedBy = "Terraform"/g' $tmp_file
          ((add_tag_count++))
          echo '✔ added tf tag'
        else
          echo '→ tag exists, skipping'
        fi
      fi
    fi
  done
  if [[ $add_tag_count -gt 0 ]]; then
    for tmp_file in tmp/*; do
      cat $tmp_file >>tf_file_updated
    done
    rm -f $tf_file
    mv tf_file_updated $tf_file
    # terraform fmt $(echo $tf_file | rev | cut -f 2- -d '/' | rev)
  fi
  rm -rf tmp
done
