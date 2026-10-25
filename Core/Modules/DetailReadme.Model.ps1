# Presentation-only resource normalization. Contextual instructions, code,
# images and multi-mod prose remain in the README's own sections.
function global:Get-DetailResourceRow {
    param([string]$Line,[switch]$AllowLabel)
    if(-not $Line -or $Line -match '^\s*!\['){return $null}
    $spans=@(Get-ReadmeInlineSpans $Line)
    $links=@($spans|Where-Object {$_.Kind -in @('destination','url') -and $_.Style -notin @('code','boldcode') -and $_.Address -match '^https?://'})
    if(-not $links.Count){return $null}
    $residue=(@($spans|Where-Object {$_.Kind -notin @('destination','url')}|ForEach-Object Text)-join '')
    $clean=$residue -replace '[\s|*\-\u2022\u00b7:;]+',''
    $label=''
    if($clean){
        if(-not $AllowLabel -or $links.Count -ne 1){return $null}
        if($Line -match '^\s*(?:[-*]\s*)?([^.!?\r\n]{1,100}):\s*https?://\S+\s*$'){$label=$matches[1].Trim(' ','-','*','|')}
        elseif($Line -match '^\s*\|\s*(?<label>[^|]+)\|\s*(?:\[[^\]]+\]\()?https?://[^|]+\|\s*$'){$label=$matches['label'].Trim().Trim('[',']','*')}
        else{return $null}
    }
    $rows=@()
    foreach($link in $links){
        $title=if($label){$label}elseif($link.Kind -eq 'destination'){$link.Text}else{''}
        if($title -match '^https?://'){$title=''}
        if(-not $title){
            $uri=[Uri]$link.Address
            $title=switch -Regex ($uri.Host){
                'discord' {if($uri.AbsolutePath -match '/channels/'){'Discussion and support'}else{'Discord invite'};break}
                'patreon' {'Patreon';break}
                'ko-fi' {'Ko-fi';break}
                'paypal' {'PayPal';break}
                'buymeacoffee' {'Buy Me a Coffee';break}
                'youtu' {'Gameplay video';break}
                'github' {if($uri.AbsolutePath -match '/releases'){'Publisher releases'}else{'Publisher project'};break}
                default {$uri.Host -replace '^www\.',''}
            }
        }
        $rows+= [pscustomobject]@{Label=$title;Url=[string]$link.Address}
    }
    return [pscustomobject]@{Links=$rows}
}

function global:Get-DetailResourceRole {
    param([string]$Url,[string]$Heading)
    if($Url -match '^https?://(?:www\.)?(?:discord\.(?:com|gg)|discordapp\.com)/'){return 'Discord discussion & support'}
    if($Url -match '^https?://(?:www\.)?(?:patreon\.com|ko-fi\.com|paypal\.(?:com|me)|buymeacoffee\.com|buymeacoffee\.co|opencollective\.com)/' -or $Heading -match '(?i)^donat') {return 'Support the mod author'}
    return 'Links'
}

function global:ConvertTo-DetailResourceContext {
    param([string]$Text,$Labels)
    $lines=[Collections.Generic.List[string]]::new();$code=$false
    $markdown='(?<!!)\[(?<label>[^\]\r\n]+)\]\((?<url>(?:[^()\r\n]|\((?<nest>)|\)(?<-nest>))*)(?(nest)(?!))\)'
    foreach($line in ($Text -split '\r?\n')){
        if($line -match '^\s*```'){$code=-not $code;$lines.Add($line);continue}
        # Commands, configuration and pictures retain their exact source.
        if($code -or $line -match '!\['){$lines.Add($line);continue}
        $parts=[Collections.Generic.List[string]]::new()
        foreach($part in [regex]::Split($line,'(`+[^`]*`+)')){
        if($part.StartsWith('`')){$parts.Add($part);continue}
        $plain=[regex]::Replace($part,$markdown,{
            param($m)
            if($m.Groups['url'].Value -match '^https?://'){return $m.Groups['label'].Value}
            return $m.Value
        })
        $plain=[regex]::Replace($plain,'(?<![\w@])(?:https?://|www\.)[^\s<>"''`]+',{
            param($m)
            $span=@(Get-ReadmeInlineSpans -Text $m.Value -Literal|Where-Object Kind -eq 'url'|Select-Object -First 1)
            if(-not $span.Count){return $m.Value}
            $key=([string]$span[0].Address).TrimEnd('/')
            if($key -match '^https?://(?:www\.)?discord\.gg/(?:flat2vr|uAeQkYBM4n)$'){$key='https://discord.gg/uAeQkYBM4n'}
            if(-not $Labels.ContainsKey($key)){return $m.Value}
            return [string]$Labels[$key]+$m.Value.Substring($span[0].Text.Length)
        })
        $parts.Add($plain)
        }
        $lines.Add(($parts -join ''))
    }
    return $lines -join "`n"
}

function global:ConvertTo-DetailReadmeModel {
    param($Game,$Sections,[string]$DiscordText)
    if(-not(Get-Command Get-ReadmeInlineSpans -ErrorAction SilentlyContinue)){
        . (Join-Path $global:HubHelpersCoreRoot 'Modules\ReadmeLinks.ps1')
    }
    $result=[ordered]@{};$buckets=[ordered]@{}
    foreach($role in @('Links','Support the mod author','Discord discussion & support')){$buckets[$role]=[Collections.Generic.List[object]]::new()}
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $notes=[ordered]@{};$keepOrder=[bool]$Sections['_keepOrder']
    # Seed the authoritative discussion routes first. This prevents an old
    # duplicate label from replacing the registry's actual channel purpose.
    $sources=[Collections.Generic.List[object]]::new()
    if($DiscordText){$sources.Add([pscustomobject]@{Heading='Discord discussion & support';Body=$DiscordText;Central=$true})}
    foreach($key in $Sections.get_Keys()){
        if(([string]$key).StartsWith('_')){$result[$key]=$Sections[$key];continue}
        $sources.Add([pscustomobject]@{Heading=[string]$key;Body=[string]$Sections[$key];Central=$false})
    }
    foreach($source in $sources){
        $heading=$source.Heading
        $resourceHeading=($heading -match '(?i)^(?:links?(?:\b| &)|resources?\b|support\b|donat|discord\b|communit|credits?\b|more info\b|related\b)')
        $remaining=[Collections.Generic.List[string]]::new();$code=$false;$extracted=$false
        foreach($line in ($source.Body -split '\r?\n')){
            if($line -match '^\s*```'){$code=-not $code;$remaining.Add($line);continue}
            if($code){$remaining.Add($line);continue}
            $row=Get-DetailResourceRow -Line $line -AllowLabel:$resourceHeading
            if(-not $row -and $resourceHeading -and $line -notmatch '!\['){
                $spans=@(Get-ReadmeInlineSpans $line)
                $web=@($spans|Where-Object {$_.Kind -in @('destination','url') -and $_.Style -notin @('code','boldcode') -and $_.Address -match '^https?://'})
                if($web.Count){
                    $row=[pscustomobject]@{Links=@($web|ForEach-Object {[pscustomobject]@{Label=$_.Text;Url=$_.Address}})}
                    # Keep meaningful ordering/join instructions while the
                    # destinations themselves become cards in their own group.
                    $context=(@($spans|ForEach-Object {if($_.Kind -eq 'url'){(Get-DetailResourceRow -Line $_.Address).Links[0].Label}else{$_.Text}}) -join '').Trim(' ','-','*','|')
                    if($context){$remaining.Add($context)}
                }
            }
            # Embedded links in real instructions are deliberately retained.
            # Resource-only rows can be styled/deduplicated without losing text.
            if(-not $row -or ($keepOrder -and -not $resourceHeading)){
                # Keep the instruction itself in place; its web destination
                # still belongs to the same canonical cards as all other pages.
                if($line -notmatch '!\['){
                    foreach($span in @(Get-ReadmeInlineSpans $line)){
                        if($span.Kind -notin @('destination','url') -or $span.Style -in @('code','boldcode') -or $span.Address -notmatch '^https?://'){continue}
                        $url=[string]$span.Address
                        if($url -match '^https?://(?:www\.)?discord\.gg/(?:flat2vr|uAeQkYBM4n)/?$'){$url='https://discord.gg/uAeQkYBM4n'}
                        if(-not $seen.Add($url.TrimEnd('/'))){continue}
                        $role=Get-DetailResourceRole $url $heading
                        $label=if($span.Kind -eq 'destination'){$span.Text}else{(Get-DetailResourceRow -Line $url).Links[0].Label}
                        if($label -match '^https?://'){$label=(Get-DetailResourceRow -Line $url).Links[0].Label}
                        if($keepOrder){$label=$heading+' - '+$label}
                        $buckets[$role].Add([pscustomobject]@{Label=$label;Url=$url})
                    }
                }
                $remaining.Add($line);continue
            }
            $extracted=$true
            foreach($link in $row.Links){
                $url=$link.Url
                if($url -match '^https?://(?:www\.)?discord\.gg/(?:flat2vr|uAeQkYBM4n)/?$'){$url='https://discord.gg/uAeQkYBM4n'}
                $identity=$url.TrimEnd('/')
                if(-not $seen.Add($identity)){continue}
                $role=Get-DetailResourceRole -Url $url -Heading $heading
                $label=$link.Label
                if($role -eq 'Support the mod author' -and $heading -match '^(?i:Support (?!the (?:mod |developer|author)|this mod).+)'){$label=$heading+' - '+$label}
                if($keepOrder -and -not $source.Central -and $heading -notmatch '^(?i:links|discord discussion & support)$'){$label=$heading+' - '+$label}
                $buckets[$role].Add([pscustomobject]@{Label=$label;Url=$url})
            }
        }
        $body=($remaining -join "`n").Trim()
        if($source.Central -and $body -eq 'Discord discussion and support channel'){$body=''}
        if($extracted -and $resourceHeading){
            # Old link tables have only their header/separator left afterwards.
            $body=(@($body -split '\r?\n'|Where-Object {$_ -notmatch '^\s*\|?(?:\s*[-:]+\s*\|)+\s*[-:]*\s*\|?\s*$' -and $_ -notmatch '^\s*\|\s*(?:Button|Link|Source|Resource|Name)\s*\|\s*(?:Action|URL|Address|Link|Destination)\s*\|\s*$'}) -join "`n").Trim()
        }
        if(-not $body){continue}
        if($heading -match '^(?i:uninstall(?: guide)?|removal|deinstall(?:ation)?|remove the (?:vr )?mod)$'){
            $result['_uninstallReadme']=([string]$result['_uninstallReadme']+"`n"+$body).Trim()
        }
        elseif($source.Central){$notes['Discord discussion & support']=$body}
        elseif($resourceHeading -and $extracted -and $heading -match '^(?i:support|donat)'){
            $role=if($buckets['Support the mod author'].Count){'Support the mod author'}else{'Links'}
            $prefix=if($notes.Contains($role)){[string]$notes[$role]+"`n`n"}else{''}
            $notes[$role]=$prefix+$body
        }
        elseif($heading -eq 'Links' -or $heading -eq 'Support the mod author' -or $heading -eq 'Discord discussion & support'){$notes[$heading]=$body}
        else{
            $canonical=switch -Regex ($heading){
                '^(?i:about)$' {'About the Game';break}
                '^(?i:what it does|overview)$' {'About this mod';break}
                default {$heading}
            }
            if($result.Contains($canonical)){$result[$canonical]+="`n`n"+$body}else{$result[$canonical]=$body}
        }
    }
    $labels=@{}
    foreach($role in $buckets.get_Keys()){foreach($link in $buckets[$role]){$labels[$link.Url.TrimEnd('/')]=$link.Label}}
    foreach($key in @($result.get_Keys())){
        if(-not $key.StartsWith('_') -or $key -eq '_uninstallReadme'){$result[$key]=ConvertTo-DetailResourceContext -Text $result[$key] -Labels $labels}
    }
    foreach($key in @($notes.get_Keys())){$notes[$key]=ConvertTo-DetailResourceContext -Text $notes[$key] -Labels $labels}
    foreach($role in $buckets.get_Keys()){
        $body=if($notes.Contains($role)){[string]$notes[$role]}else{''}
        foreach($link in $buckets[$role]){
            if($body){$body+="`n"}
            $label=$link.Label.Replace('[','(').Replace(']',')')
            $body+='- ['+$label+']('+$link.Url+')'
        }
        if($body){$result[$role]=$body}
    }
    # The page has one dedicated final Discord block; do not render a second
    # copy through the normal README section ordering.
    $discord=if($result.Contains('Discord discussion & support')){[string]$result['Discord discussion & support']}else{''}
    if($result.Contains('Discord discussion & support')){$result.Remove('Discord discussion & support')}
    return [pscustomobject]@{Sections=$result;DiscordText=$discord;ResourceCount=$seen.Count}
}

function global:New-DetailResourceCards {
    param($Links,[int]$Font=13)
    $wrap=[Windows.Controls.WrapPanel]::new();$wrap.MaxWidth=1040
    foreach($resource in $Links){
        $card=[Windows.Controls.Border]::new();$card.Width=218;$card.MinHeight=52
        $card.CornerRadius=[Windows.CornerRadius]::new(6);$card.Padding=[Windows.Thickness]::new(10,6,10,6);$card.Margin=[Windows.Thickness]::new(0,0,8,8)
        $card.Background=[Windows.Media.BrushConverter]::new().ConvertFromString('#1b1b25')
        $card.BorderBrush=[Windows.Media.BrushConverter]::new().ConvertFromString('#30303d');$card.BorderThickness=[Windows.Thickness]::new(1)
        $stack=[Windows.Controls.StackPanel]::new();$label=[Windows.Controls.TextBlock]::new()
        $label.FontSize=$Font;$label.FontWeight='SemiBold';$label.TextWrapping='Wrap'
        [void]$label.Inlines.Add((New-ReadmeWebLink -Text $resource.Label -Address $resource.Url))
        [void]$stack.Children.Add($label)
        if($null -ne $global:DetailReadmeTextBlocks){[void]$global:DetailReadmeTextBlocks.Add($label)}
        $hostName=[Windows.Controls.TextBlock]::new();$hostName.Text=([Uri]$resource.Url).Host -replace '^www\.',''
        $hostName.FontSize=[Math]::Max(10,$Font-2);$hostName.Foreground=[Windows.Media.BrushConverter]::new().ConvertFromString('#9292a6')
        $hostName.TextTrimming='CharacterEllipsis';[void]$stack.Children.Add($hostName)
        $card.Child=$stack;[void]$wrap.Children.Add($card)
    }
    return $wrap
}
