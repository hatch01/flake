{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  pandocCommand = "--mathjax --toc --wrap=preserve -L /home/eymeric/.local/share/pandoc/filters/search_replace/filter.lua --filter=/home/eymeric/.local/share/pandoc/filters/asciimathml-pandocfilter/asciimathfilter.js --filter mermaid-filter -f markdown+hard_line_breaks --template eisvogel";
in {
  options = {
    ghostwriter.enable = mkEnableOption "Enable ghostwriter";
  };

  config = mkIf config.ghostwriter.enable {
    environment.systemPackages = with pkgs; [
      kdePackages.ghostwriter
      pandoc_3_6
      nodejs
      texlive.combined.scheme-full
      mermaid-cli
      mermaid-filter
      librsvg
    ];
    hm = {
      programs.zsh.initExtra = ''
        md2pdf(){
          md2 pdf $@
        }

        md2(){
          for param in "''${@:2}"
            do
                filename="''${param%.*}"
                extension="''${param##*.}"
                if [[ "$extension" == "md" ]]; then
                echo converting $param to $filename.$1
                    if [[ "$1" == "pdf" ]]; then
                    MERMAID_FILTER_FORMAT=pdf pandoc ${pandocCommand} $param -o $filename.$1
                    else
                    pandoc ${pandocCommand} $param -o $filename.$1
                    fi
                else
                echo "File $param is not a markdown file $extension"
                fi
          done
        }
      '';
      home.file."Nextcloud/ecole/polytech/md_to_pdf.sh" = {
        text = ''
              wd="/home/eymeric/Nextcloud/ecole/polytech/"
              find "$wd" -type f -name "*.md" -print0 | grep -z -v -E "markdown|Universe" | while IFS= read -r -d ''' i; do
              path=$(echo $i | sed -e "s/$(echo $i |rev | cut -d "/" -f1 | rev)//")
              mkdir -p $path/pdf
              pdfFile=''${path}pdf/$(echo $i | rev | cut -d "/" -f1 | rev | sed -e "s/.md/.pdf/")
              mkdir -p $path/html
              htmlFile=''${path}html/$(echo $i | rev | cut -d "/" -f1 | rev | sed -e "s/.md/.html/")
              mkdir -p $path/markdown
              markdownFile=''${path}markdown/$(echo $i | rev | cut -d "/" -f1 | rev)
              if [[ ( -f $pdfFile && $(stat -c %Y $pdfFile) -lt $(stat -c %Y $i) ) ||  ( ! -e $pdfFile ) ]]
              then
                  echo "Converting $i to $pdfFile"
                  cd $path
                  MERMAID_FILTER_FORMAT=pdf MERMAID_FILTER_BACKGROUND=transparent pandoc ${pandocCommand} $i -o $pdfFile
              fi
              if [[ ( -f $htmlFile && $(stat -c %Y $htmlFile) -lt $(stat -c %Y $i) ) ||  ( ! -e $htmlFile ) ]]
              then
                  echo "Converting $i to $htmlFile"
                  cd $path
                  MERMAID_FILTER_FORMAT=svg MERMAID_FILTER_BACKGROUND=transparent pandoc ${pandocCommand} $i -o $htmlFile
              fi

              if [[ ( -f $markdownFile && $(stat -c %Y $markdownFile) -lt $(stat -c %Y $i) ) ||  ( ! -e $markdownFile ) ]]
              then
                  echo "Converting $i to $markdownFile"
                  cd $path
                  MERMAID_FILTER_FORMAT=svg MERMAID_FILTER_BACKGROUND=transparent pandoc ${builtins.replaceStrings ["--template eisvogel" ""] ["" ""] pandocCommand} $i -o $markdownFile
              fi
          done
        '';
        executable = true;
        force = true;
      };

      home.file.".local/share/pandoc/filters/asciimathml-pandocfilter" = {
        source = pkgs.fetchFromGitHub {
          owner = "hatch01";
          repo = "asciimathml-pandocfilter";
          rev = "2610212edd8feeda38c8039c619d20f25622b8c6";
          hash = "sha256-82UbeOQGjsMq3HQ3VoOKNQBkolvGlsjsqS+yDwDG2jc=";
        };
        force = true;
        executable = true;
        #onChange = "${lib.getExe' pkgs.nodejs "npm"} install -g pandoc-filter";
      };
      home.file.".local/share/pandoc/filters/search_replace" = {
        source = pkgs.fetchFromGitHub {
          owner = "hatch01";
          repo = "search_replace_pandoc";
          rev = "fd2445dd3d269afd3660aa01ec5f3a8997877ea0";
          hash = "sha256-Ub15YKim4c2Dl2uriiERpc48BGJe+Vyh/11vQ802SMA=";
        };
        force = true;
        executable = true;
      };
      home.file.".local/share/pandoc/templates" = {
        source = pkgs.fetchFromGitHub {
          owner = "hatch01";
          repo = "pandoc_templates";
          rev = "main";
          hash = "sha256-qzswZ+YyS8XpxBfEVL4U4uiaaR7y3EnrsoWdqijF/yk=";
        };
        force = true;
      };
      systemd.user.services.lesson_generator = {
        Unit = {
          Description = "generate my lessons using pandoc";
        };
        Service = {
          ExecStart = toString (
            pkgs.writeShellScript "lesson-generator-script" ''
              set -eou pipefail
              ${pkgs.bash}/bin/bash "/home/eymeric/Nextcloud/ecole/polytech/md_to_pdf.sh";
            ''
          );
        };
        Install.WantedBy = ["default.target"];
      };

      systemd.user.timers.lesson_generator = {
        Unit = {
          Description = "timer to generate my lessons";
        };
        Timer = {
          Unit = "lesson_generator.service"; # Corrected to reference the service unit
          OnCalendar = "*:0/15";
          Persistent = true;
        };
        Install.WantedBy = ["timers.target"];
      };

      programs.plasma = {
        configFile = {
          "kde.org/ghostwriter.conf" = {
            "Preview" = {
              "lastUsedExporter".value = "Pandoc";
              "lastUsedExporterParams".value = "\"${pandocCommand}\"";
            };
            "Save" = {
              "autoSave".value = true;
              "backupFile".value = true;
            };
            "Backup" = {
              "location".value = "/home/eymeric/.local/share/ghostwriter/backups/";
            };
            "Export" = {
              "lastUsedExporter".value = "Pandoc";
              "lastUsedExporterFormat".value = "OpenDocument Text";
              "lastUsedExporterParams".value = "\"${pandocCommand}\"";
              "openOnExport".value = true;
              "smartTypographyEnabled".value = true;
            };
            "FindReplace" = {
              "highlightMatches".value = true;
              "matchCase".value = true;
              "regularExpression".value = false;
              "wholeWord".value = false;
            };
            "Session" = {
              "favoriteStatistic".value = 1;
              "rememberFileHistory".value = true;
              "restoreSession".value = true;
            };
            "Spelling" = {
              "liveSpellCheck".value = true;
            };
          };
        };
      };
    };
  };
}
