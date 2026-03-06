#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_FILE="${1:-$ROOT_DIR/design/token.pen}"
OUTPUT_FILE="${2:-$ROOT_DIR/docs/token-style-guidance.tokens.json}"

jq --arg source_file "$SOURCE_FILE" '
  def clean_name: ascii_downcase | gsub("[^a-z0-9]+";"_") | gsub("^_|_$"; "");
  ( .children[] | select(.id=="qvpHw") |
    [.. | objects |
      select(.type=="rectangle" and (.fill|type=="string") and (.name|test("^Rectangle"))) |
      {id,name,fill,x,y,width,height}
    ] | sort_by(.y,.x)
  ) as $color_swatches |
  ( .children[] | select(.id=="1UV2S") |
    [.. | objects |
      select(.type=="text" and (.content|type=="string") and (.content|contains("Manrope"))) |
      {
        token: ((.content | split(" / ")[0]) | clean_name),
        label: .content,
        font_family: .fontFamily,
        font_size: .fontSize,
        font_weight_source: .fontWeight,
        font_weight_intended: (
          if (.content|contains("Bold")) then 700
          elif (.content|contains("Medium")) then 500
          elif (.content|contains("Regular")) then 400
          else null end
        ),
        line_height: (.lineHeight // null),
        letter_spacing: (.letterSpacing // null),
        color: .fill
      }
    ]
  ) as $type_scale |
  {
    meta: {
      source_file: $source_file,
      generated_for: "pixel-perfect calibration",
      generated_at_utc_epoch: now
    },
    tokens: {
      colors: {
        palette_from_colors_frame: (
          $color_swatches
          | to_entries
          | map(
              .value + {
                slot: (
                  [
                    "header_band",
                    "brand_primary",
                    "brand_success",
                    "brand_warning",
                    "brand_accent_orange",
                    "brand_danger",
                    "neutral_bg_base",
                    "neutral_bg_surface",
                    "neutral_bg_elevated",
                    "neutral_text_muted",
                    "neutral_text_soft",
                    "neutral_white"
                  ][.key]
                )
              }
            )
        ),
        all_unique_fill_values: ([.. | objects | .fill? | select(type=="string")] | unique | sort),
        all_unique_stroke_fill_values: ([.. | objects | .stroke?.fill? | select(type=="string")] | unique | sort)
      },
      typography: {
        primary_font_family: "Manrope",
        secondary_font_family: "Poppins",
        section_label_font_family: "Ubuntu",
        scale: $type_scale,
        all_font_families_used: ([.. | objects | .fontFamily? | select(type=="string")] | unique | sort),
        all_font_sizes_used: ([.. | objects | .fontSize? | select(type=="number")] | unique | sort)
      },
      radius: {
        core: {
          xs: 5,
          sm: 6,
          md: 16,
          lg: 24,
          xl: 40,
          capsule: 43,
          full: 100
        },
        all_unique_corner_radius_values: ([.. | objects | .cornerRadius? | select(type=="number")] | unique | sort)
      },
      spacing: {
        gap_values: ([.. | objects | .gap? | select(type=="number")] | unique | sort),
        padding_values_numeric: ([.. | objects | .padding? | select(type=="number")] | unique | sort),
        padding_values_array: ([.. | objects | .padding? | select(type=="array")] | unique),
        recommended_scale: [2,4,6,8,10,12,14,16,20,24,40,56,80]
      }
    }
  }
' "$SOURCE_FILE" > "$OUTPUT_FILE"

echo "Exported tokens:"
echo "  source: $SOURCE_FILE"
echo "  output: $OUTPUT_FILE"
