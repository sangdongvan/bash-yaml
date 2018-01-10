
# Read YAML file from Bash script
#
# Arguments:
#   1. filepath: YAML filepath to read content
#   2. prefix: The prefix of assigning variable (e.g: "credential_")
#
# Ref:
#   - https://github.com/jasperes/bash-yaml
#
# Known issue:
#   - Can't interpret the Array/List syntax on zsh
function _parse_yaml() {
    local yaml_file=$1
    local prefix=$2
    local s
    local w
    local fs

    s='[[:space:]]*'
    w='[a-zA-Z0-9_.-]*'
    fs="$(echo @|tr @ '\034')"

    (
        sed -ne '/^--/s|--||g; s|\"|\\\"|g; s/\s*$//g;' \
            -e "/#.*[\"\']/!s| #.*||g; /^#/s|#.*||g;" \
            -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" |

        awk -F"$fs" '{
            indent = length($1)/2;
            if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
                if (length($3) > 0) {
                    vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
                }
            }' |

        sed -e 's/_=/+=/g' \
            -e '/\..*=/s|\.|_|' \
            -e '/\-.*=/s|\-|_|'

    ) < "$yaml_file"
}


# Derive bash variables from YAML file
#
# Arguments:
#   1. yaml_file: YAML filepath to derive
#   2. prefile: Prepend the prefix to all discovered variables
#
# How to use:
#   ```bash
#   _expose_variables_from_yaml credential.yml
#   _expose_variables_from_yaml credential.yml prefix_
#   ```
#
# FAQs:
#   1. Does it support list and array?
#   A: No, this parser is for simple credential yml file
#
#   2. Does it support multiple YAML in a single file?
#   A: Yes
#
#   3. What kind of YAML syntaxs that this function supports?
#   A: https://github.com/jasperes/bash-yaml/blob/master/test/file.yml
#      IMPORTANT this parser don't support yaml list/array
#
#   4. How to use this function?
#   A: https://github.com/jasperes/bash-yaml/blob/master/test/test.sh
#
# Ref:
#   - https://github.com/jasperes/bash-yaml
function _expose_variables_from_yaml() {
    local yaml_file="$1"
    local prefix="$2"
    eval "$(_parse_yaml "$yaml_file" "$prefix")"
}
