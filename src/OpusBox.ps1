# OpusBox
# Modern Windows WPF front-end for yt-dlp + MusicBrainz Picard
# Requires Windows PowerShell 5.1+, yt-dlp/FFmpeg (Stacher paths supported), and MusicBrainz Picard.

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$ErrorActionPreference = "Stop"

# ----------------------------
# Helpers / defaults
# ----------------------------
function Find-FirstExistingPath {
    param([string[]]$Paths)
    foreach ($p in $Paths) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    return ""
}

function Sanitize-FileName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return "YouTube Album" }
    foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) {
        $Name = $Name.Replace($c, '_')
    }
    $Name = $Name.Trim().TrimEnd('.')
    if ([string]::IsNullOrWhiteSpace($Name)) { return "YouTube Album" }
    return $Name
}


function Get-SettingsPath {
    $dir = Join-Path $env:APPDATA "OpusBox"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return (Join-Path $dir "settings.json")
}

$DefaultYtDlp = Find-FirstExistingPath @(
    "$env:USERPROFILE\.stacher\yt-dlp.exe",
    "$PSScriptRoot\yt-dlp.exe"
)

$DefaultFfmpeg = Find-FirstExistingPath @(
    "$env:USERPROFILE\.stacher\ffmpeg.exe",
    "$PSScriptRoot\ffmpeg.exe"
)

$DefaultPicard = Find-FirstExistingPath @(
    "$env:ProgramFiles\MusicBrainz Picard\picard.exe",
    "${env:ProgramFiles(x86)}\MusicBrainz Picard\picard.exe",
    "$env:LOCALAPPDATA\Programs\MusicBrainz Picard\picard.exe"
)

$DefaultOutput = "$env:USERPROFILE\Desktop\Music"

# ----------------------------
# Modern WPF UI
# ----------------------------
[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="OpusBox"
    Width="900"
    Height="720"
    MinWidth="760"
    MinHeight="620"
    WindowStartupLocation="CenterScreen"
    Background="#0B0D12"
    Foreground="#F5F7FB"
    FontFamily="Segoe UI"
    ResizeMode="CanResize">
    <Window.Resources>
        <SolidColorBrush x:Key="Bg" Color="#0B0D12"/>
        <SolidColorBrush x:Key="Panel" Color="#12151C"/>
        <SolidColorBrush x:Key="Panel2" Color="#181C25"/>
        <SolidColorBrush x:Key="Border" Color="#272C38"/>
        <SolidColorBrush x:Key="Muted" Color="#8F98A8"/>
        <SolidColorBrush x:Key="Text" Color="#F5F7FB"/>
        <SolidColorBrush x:Key="Accent" Color="#8B5CF6"/>
        <SolidColorBrush x:Key="AccentHover" Color="#9F75FF"/>
        <SolidColorBrush x:Key="Good" Color="#37D67A"/>
        <SolidColorBrush x:Key="Warn" Color="#F5B942"/>

        <Style TargetType="TextBox">
            <Setter Property="Foreground" Value="{StaticResource Text}"/>
            <Setter Property="Background" Value="#0F1218"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,9"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="CaretBrush" Value="White"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Background" Value="{StaticResource Accent}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="18,10"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="9" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{StaticResource AccentHover}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bd" Property="Opacity" Value="0.45"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Foreground" Value="{StaticResource Text}"/>
            <Setter Property="Background" Value="#1A1F29"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,9"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#242A36"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource Text}"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>

        <Style TargetType="ProgressBar">
            <Setter Property="Height" Value="8"/>
            <Setter Property="Foreground" Value="{StaticResource Accent}"/>
            <Setter Property="Background" Value="#252A35"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>

        <!-- Slim dark scrollbar for the Status / Advanced / Log panel -->
        <Style x:Key="ModernThumbStyle" TargetType="Thumb">
            <Setter Property="Background" Value="#4A5160"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Thumb">
                        <Border x:Name="ThumbBorder"
                                Background="{TemplateBinding Background}"
                                CornerRadius="4"
                                Margin="2,0"/>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ThumbBorder" Property="Background" Value="#697386"/>
                            </Trigger>
                            <Trigger Property="IsDragging" Value="True">
                                <Setter TargetName="ThumbBorder" Property="Background" Value="{StaticResource Accent}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ModernScrollBarStyle" TargetType="ScrollBar">
            <Setter Property="Width" Value="10"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="Transparent" Width="{TemplateBinding Width}">
                            <Track x:Name="PART_Track"
                                   IsDirectionReversed="True"
                                   Focusable="False">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageUpCommand"
                                                  Opacity="0"
                                                  Focusable="False"/>
                                </Track.DecreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb Style="{StaticResource ModernThumbStyle}"/>
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageDownCommand"
                                                  Opacity="0"
                                                  Focusable="False"/>
                                </Track.IncreaseRepeatButton>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="{x:Type ScrollBar}" BasedOn="{StaticResource ModernScrollBarStyle}"/>
    </Window.Resources>

    <Grid Margin="26">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Grid Grid.Row="0" Margin="0,0,0,22">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <Border Width="48" Height="48" CornerRadius="14" Background="#8B5CF6">
                <TextBlock Text="♫" FontSize="25" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="White"/>
            </Border>

            <StackPanel Grid.Column="1" Margin="14,0,0,0" VerticalAlignment="Center">
                <TextBlock Text="OpusBox" FontSize="25" FontWeight="SemiBold"/>
                <TextBlock Text="YouTube → Opus → MusicBrainz" Foreground="{StaticResource Muted}" FontSize="13" Margin="0,3,0,0"/>
            </StackPanel>

            <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                <Button x:Name="TagLibraryButton"
                        Style="{StaticResource SecondaryButton}"
                        Content="Tag Existing Music"
                        Margin="0,0,10,0"
                        Padding="13,8"/>

                <Border CornerRadius="14"
                        Background="#151922"
                        BorderBrush="{StaticResource Border}"
                        BorderThickness="1"
                        Padding="11,7">
                    <StackPanel Orientation="Horizontal">
                        <Ellipse x:Name="HealthDot" Width="8" Height="8" Fill="{StaticResource Good}" Margin="0,0,7,0"/>
                        <TextBlock x:Name="HealthText" Text="Tools ready" FontSize="12" Foreground="#CAD0DA"/>
                    </StackPanel>
                </Border>
            </StackPanel>
        </Grid>

        <!-- URL -->
        <Border Grid.Row="1" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="14" Padding="18" Margin="0,0,0,16">
            <StackPanel>
                <TextBlock Text="YouTube album or playlist" FontWeight="SemiBold" FontSize="14" Margin="0,0,0,8"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox x:Name="UrlBox" Grid.Column="0" Height="42" ToolTip="Paste a YouTube album or playlist URL"/>
                    <Button x:Name="PreviewButton" Grid.Column="2" Style="{StaticResource SecondaryButton}" Content="Load album" MinWidth="108"/>
                </Grid>
            </StackPanel>
        </Border>

        <!-- Album preview -->
        <Border x:Name="PreviewCard" Grid.Row="2" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="14" Padding="18" Margin="0,0,0,16">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="104"/>
                    <ColumnDefinition Width="18"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <Border Width="104" Height="104" CornerRadius="11" Background="#1B202A" ClipToBounds="True">
                    <Grid>
                        <TextBlock x:Name="CoverPlaceholder" Text="♫" FontSize="38" Foreground="#697386" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        <Image x:Name="CoverImage" Stretch="UniformToFill"/>
                    </Grid>
                </Border>

                <StackPanel Grid.Column="2" VerticalAlignment="Center">
                    <TextBlock x:Name="AlbumTitleText" Text="No album loaded" FontSize="20" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                    <TextBlock x:Name="AlbumMetaText" Text="Paste a link above and load the album." Foreground="{StaticResource Muted}" FontSize="13" Margin="0,7,0,0"/>
                    <StackPanel Orientation="Horizontal" Margin="0,12,0,0">
                        <Border Background="#1D2330" CornerRadius="7" Padding="9,5" Margin="0,0,8,0">
                            <TextBlock x:Name="TrackCountBadge" Text="— tracks" Foreground="#C8D0DC" FontSize="12"/>
                        </Border>
                        <Border Background="#1D2330" CornerRadius="7" Padding="9,5">
                            <TextBlock Text="OPUS" Foreground="#C8D0DC" FontSize="12" FontWeight="SemiBold"/>
                        </Border>
                    </StackPanel>
                </StackPanel>

                <Button x:Name="DownloadButton" Grid.Column="3" Style="{StaticResource PrimaryButton}" Content="Download &amp; Process" MinWidth="150" Height="44" VerticalAlignment="Center"/>
            </Grid>
        </Border>

        <!-- Main content -->
        <Grid Grid.Row="3">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="1.55*"/>
                <ColumnDefinition Width="16"/>
                <ColumnDefinition Width="1*"/>
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="14" Padding="18">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Grid Grid.Row="0" Margin="0,0,0,13">
                        <TextBlock Text="Tracks" FontSize="15" FontWeight="SemiBold"/>
                        <TextBlock x:Name="TrackStatusText" Text="Waiting" HorizontalAlignment="Right" Foreground="{StaticResource Muted}" FontSize="12"/>
                    </Grid>

                    <ProgressBar x:Name="OverallProgress" Grid.Row="1" Minimum="0" Maximum="100" Value="0" Margin="0,0,0,14"/>

                    <ListBox x:Name="TrackList" Grid.Row="2" Background="Transparent" BorderThickness="0" Foreground="{StaticResource Text}" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                        <ListBox.ItemTemplate>
                            <DataTemplate>
                                <Grid Margin="0,4">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="30"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Border Width="23" Height="23" CornerRadius="7" Background="#1D2330" VerticalAlignment="Center">
                                        <TextBlock Text="{Binding Index}" HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="11" Foreground="#AAB3C2"/>
                                    </Border>
                                    <TextBlock Grid.Column="1" Text="{Binding Title}" Margin="9,0,0,0" VerticalAlignment="Center" TextTrimming="CharacterEllipsis" FontSize="13"/>
                                </Grid>
                            </DataTemplate>
                        </ListBox.ItemTemplate>
                    </ListBox>
                </Grid>
            </Border>

            <Border Grid.Column="2" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="14" Padding="18">
                <ScrollViewer VerticalScrollBarVisibility="Auto"
                              HorizontalScrollBarVisibility="Disabled"
                              CanContentScroll="False"
                              Padding="0,0,4,0">
                    <StackPanel>
                    <TextBlock Text="Status" FontSize="15" FontWeight="SemiBold" Margin="0,0,0,15"/>

                    <Border Background="#171B24" CornerRadius="10" Padding="13" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock x:Name="StatusTitle" Text="Ready when you are" FontWeight="SemiBold" FontSize="13"/>
                            <TextBlock x:Name="StatusDetail" Text="Load an album to get started." Foreground="{StaticResource Muted}" FontSize="12" Margin="0,5,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Border>

                    <TextBlock Text="Save location" Foreground="{StaticResource Muted}" FontSize="11" Margin="0,4,0,5"/>
                    <TextBlock x:Name="SaveLocationText" Text="" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,15"/>

                    <Expander x:Name="AdvancedExpander" Header="Advanced settings" Foreground="{StaticResource Text}" Margin="0,0,0,10">
                        <StackPanel Margin="0,12,0,0">
                            <TextBlock Text="Music folder" Foreground="{StaticResource Muted}" FontSize="11" Margin="0,0,0,4"/>
                            <Grid Margin="0,0,0,10">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="8"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBox x:Name="OutputBox" Height="36" Grid.Column="0" FontSize="12" Padding="9,6"/>
                                <Button x:Name="BrowseOutputButton" Grid.Column="2" Style="{StaticResource SecondaryButton}" Content="Browse" Padding="10,7"/>
                            </Grid>

                            <TextBlock Text="yt-dlp.exe" Foreground="{StaticResource Muted}" FontSize="11" Margin="0,0,0,4"/>
                            <TextBox x:Name="YtDlpBox" Height="34" FontSize="11" Padding="8,5" Margin="0,0,0,9"/>

                            <TextBlock Text="Picard.exe" Foreground="{StaticResource Muted}" FontSize="11" Margin="0,0,0,4"/>
                            <TextBox x:Name="PicardBox" Height="34" FontSize="11" Padding="8,5" Margin="0,0,0,10"/>

                            <CheckBox x:Name="AutoTagCheck" Content="Automatically process tags after download" IsChecked="True" Margin="0,0,0,8"/>
                            <CheckBox x:Name="OpenFolderCheck" Content="Open album folder when finished" IsChecked="True"/>
                        </StackPanel>
                    </Expander>

                    <Expander x:Name="LogExpander" Header="View log" Foreground="{StaticResource Text}">
                        <TextBox x:Name="LogBox" Margin="0,10,0,0" Height="145" IsReadOnly="True" AcceptsReturn="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="10" Background="#0D1016"/>
                    </Expander>
                    </StackPanel>
                </ScrollViewer>
            </Border>
        </Grid>

        <Grid Grid.Row="4" Margin="0,17,0,0">
            <TextBlock Text="OpusBox keeps the audio as Opus. Picard only updates tags and artwork." Foreground="{StaticResource Muted}" FontSize="11"/>
            <TextBlock x:Name="FooterState" Text="Idle" HorizontalAlignment="Right" Foreground="{StaticResource Muted}" FontSize="11"/>
        </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [Windows.Markup.XamlReader]::Load($reader)

$names = @(
    "HealthDot","HealthText","TagLibraryButton","UrlBox","PreviewButton","PreviewCard","CoverImage","CoverPlaceholder",
    "AlbumTitleText","AlbumMetaText","TrackCountBadge","DownloadButton","TrackStatusText",
    "OverallProgress","TrackList","StatusTitle","StatusDetail","SaveLocationText",
    "AdvancedExpander","OutputBox","BrowseOutputButton","YtDlpBox","PicardBox","AutoTagCheck",
    "OpenFolderCheck","LogExpander","LogBox","FooterState"
)
foreach ($n in $names) { Set-Variable -Name $n -Value $Window.FindName($n) -Scope Script }

# ----------------------------
# Runtime state
# ----------------------------
$script:CurrentProcess = $null
$script:StdoutTask = $null
$script:StderrTask = $null
$script:JobMode = ""
$script:JobOutput = New-Object System.Collections.Generic.List[string]
$script:PendingDownload = $false
$script:PendingPreviewAfterResolve = $false
$script:OriginalMusicUrl = ""
$script:AlbumTitle = ""
$script:AlbumFolder = ""
$script:ResolvedUrl = ""
$script:AlbumThumb = ""
$script:TrackCount = 0
$script:LargePlaylistCutoff = 50

$script:DownloadedThisRun = 0
$script:SkippedThisRun = 0
$script:FailedThisRun = New-Object System.Collections.Generic.List[object]
$script:FailedReportPath = ""
$script:ArchiveFile = ""

$script:DownloadArgs = @()
$script:LastArchiveCount = 0
$script:LastProgressTime = Get-Date
$script:WatchdogRestartPending = $false
$script:WatchdogRestarts = 0
$script:WatchdogMaxRestarts = 3
$script:WatchdogStallSeconds = 180

$script:NewFilesBeforeRun = @{}
$script:TagCandidates = @()
$script:TagBatchSize = 25
$script:TagWaitSeconds = 45

$script:CurrentTrack = 0
$script:Tracks = @()

function Write-Log {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return }
    $stamp = Get-Date -Format "HH:mm:ss"
    $LogBox.AppendText("[$stamp] $Text`r`n")
    $LogBox.ScrollToEnd()
}

function Set-Status {
    param(
        [string]$Title,
        [string]$Detail,
        [string]$Footer = $null
    )
    $StatusTitle.Text = $Title
    $StatusDetail.Text = $Detail
    if ($Footer) { $FooterState.Text = $Footer }
}

function Set-Busy {
    param([bool]$Busy)
    $PreviewButton.IsEnabled = -not $Busy
    $DownloadButton.IsEnabled = -not $Busy
    $UrlBox.IsEnabled = -not $Busy
}

function Update-ToolHealth {
    $ytOk = Test-Path $YtDlpBox.Text
    $picardOk = Test-Path $PicardBox.Text
    if ($ytOk -and $picardOk) {
        $HealthDot.Fill = [Windows.Media.Brushes]::LightGreen
        $HealthText.Text = "Tools ready"
    } elseif ($ytOk) {
        $HealthDot.Fill = [Windows.Media.Brushes]::Goldenrod
        $HealthText.Text = "Picard not found"
    } else {
        $HealthDot.Fill = [Windows.Media.Brushes]::IndianRed
        $HealthText.Text = "yt-dlp not found"
    }
}

function Load-Settings {
    $OutputBox.Text = $DefaultOutput
    $YtDlpBox.Text = $DefaultYtDlp
    $PicardBox.Text = $DefaultPicard

    $path = Get-SettingsPath
    if (Test-Path $path) {
        try {
            $s = Get-Content $path -Raw | ConvertFrom-Json
            if ($s.output) { $OutputBox.Text = $s.output }
            if ($s.ytdlp) { $YtDlpBox.Text = $s.ytdlp }
            if ($s.picard) { $PicardBox.Text = $s.picard }
            if ($null -ne $s.autotag) { $AutoTagCheck.IsChecked = [bool]$s.autotag }
            if ($null -ne $s.openfolder) { $OpenFolderCheck.IsChecked = [bool]$s.openfolder }
        } catch {}
    }
    $SaveLocationText.Text = $OutputBox.Text
    Update-ToolHealth
}

function Save-Settings {
    try {
        $obj = [ordered]@{
            output = $OutputBox.Text
            ytdlp = $YtDlpBox.Text
            picard = $PicardBox.Text
            autotag = [bool]$AutoTagCheck.IsChecked
            openfolder = [bool]$OpenFolderCheck.IsChecked
        }
        $obj | ConvertTo-Json | Set-Content (Get-SettingsPath) -Encoding UTF8
    } catch {}
}

function Set-Cover {
    param([string]$Url)
    $CoverImage.Source = $null
    $CoverPlaceholder.Visibility = "Visible"
    if ([string]::IsNullOrWhiteSpace($Url)) { return }
    try {
        $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
        $bmp.BeginInit()
        $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bmp.UriSource = New-Object System.Uri($Url)
        $bmp.EndInit()
        $CoverImage.Source = $bmp
        $CoverPlaceholder.Visibility = "Collapsed"
    } catch {
        Write-Log "Could not load album artwork preview."
    }
}

function Convert-ToProcessArgumentString {
    param([string[]]$Arguments)

    # Windows CreateProcess receives a single command-line string. Quote every
    # argument so characters common in YouTube URLs (notably &, = and ?) are
    # passed directly to yt-dlp instead of being interpreted or dropped.
    $quoted = foreach ($arg in $Arguments) {
        if ($null -eq $arg) { $arg = "" }

        # CommandLineToArgvW-compatible quoting:
        # escape backslashes that precede a quote and trailing backslashes.
        $a = [string]$arg
        $a = $a -replace '(\\*)"', '$1$1\"'
        $a = $a -replace '(\\+)$', '$1$1'
        '"' + $a + '"'
    }
    return ($quoted -join ' ')
}

function Start-BackgroundCommand {
    param(
        [string]$Mode,
        [string]$Exe,
        [string[]]$CommandArgs
    )

    if ($script:CurrentProcess) {
        try {
            if (-not $script:CurrentProcess.HasExited) { $script:CurrentProcess.Kill() }
            $script:CurrentProcess.Dispose()
        } catch {}
    }

    $script:JobMode = $Mode

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Exe
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.Arguments = Convert-ToProcessArgumentString $CommandArgs

    $urlArg = $CommandArgs | Where-Object { $_ -match '^https?://' } | Select-Object -Last 1
    Write-Log ("Launching {0}; URL: {1}" -f $Mode, $urlArg)

    $script:CurrentProcess = New-Object System.Diagnostics.Process
    $script:CurrentProcess.StartInfo = $psi

    [void]$script:CurrentProcess.Start()

    # Important: don't use PowerShell OutputDataReceived event handlers here.
    # Those callbacks run on worker threads without a PowerShell runspace and can
    # terminate the whole GUI. Let .NET collect both streams asynchronously instead.
    $script:StdoutTask = $script:CurrentProcess.StandardOutput.ReadToEndAsync()
    $script:StderrTask = $script:CurrentProcess.StandardError.ReadToEndAsync()
}


function Start-MusicUrlResolve {
    param([string]$MusicUrl)

    $script:OriginalMusicUrl = $MusicUrl
    $script:PendingPreviewAfterResolve = $true

    Set-Busy $true
    $OverallProgress.IsIndeterminate = $true
    $TrackList.ItemsSource = $null
    $AlbumTitleText.Text = "Resolving YouTube Music link…"
    $AlbumMetaText.Text = "Letting yt-dlp return the regular YouTube playlist URL"
    $TrackCountBadge.Text = "— tracks"
    Set-Status "Resolving link" "YouTube Music detected. Getting yt-dlp's redirected YouTube URL first." "Resolving"
    Write-Log "OpusBox crash-safe process build."
    Write-Log "YouTube Music link detected."
    Write-Log "Running yt-dlp once to capture its redirected URL."

    $resolveArgs = @(
        "--flat-playlist",
        "--playlist-items", "1",
        "--print", "%(playlist_title)s",
        $MusicUrl
    )

    Start-BackgroundCommand -Mode "resolve" -Exe $YtDlpBox.Text -CommandArgs $resolveArgs
}

function Start-Preview {
    if (-not (Test-Path $YtDlpBox.Text)) {
        $AdvancedExpander.IsExpanded = $true
        [System.Windows.MessageBox]::Show("I can't find yt-dlp.exe. Set the path under Advanced settings.", "OpusBox")
        return
    }

    $url = $UrlBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($url)) {
        [System.Windows.MessageBox]::Show("Paste a YouTube album or playlist URL first.", "OpusBox")
        return
    }

    # Simple flow requested:
    # 1. If it is a music.youtube.com URL, ask yt-dlp for the redirect.
    # 2. Capture the redirected www.youtube.com URL.
    # 3. Put that URL into the box.
    # 4. Run the normal OpusBox preview/download flow.
    if ($url -match '(^|//)music\.youtube\.com') {
        Start-MusicUrlResolve $url
        return
    }

    $script:ResolvedUrl = $url

    Set-Busy $true
    $OverallProgress.IsIndeterminate = $true
    $TrackList.ItemsSource = $null
    $AlbumTitleText.Text = "Reading album…"
    $AlbumMetaText.Text = "Asking yt-dlp for playlist information"
    $TrackCountBadge.Text = "— tracks"
    Set-Status "Loading album" "Reading the playlist before downloading anything." "Reading metadata"
    Write-Log "OpusBox direct-process build."
    Write-Log "OpusBox watchdog build."
    Write-Log "OpusBox live-progress build."
    Write-Log "OpusBox auto-process build."
    Write-Log "OpusBox resume-safe build."
    Write-Log "OpusBox batch-tag build."
    Write-Log "OpusBox split-stream preview build."
    Write-Log "Loading playlist information."

    $previewArgs = @(
        "--flat-playlist",
        "--dump-single-json",
        "--no-warnings",
        $script:ResolvedUrl
    )
    Start-BackgroundCommand -Mode "preview" -Exe $YtDlpBox.Text -CommandArgs $previewArgs
}

function Start-Download {
    if (-not $script:AlbumTitle) {
        $script:PendingDownload = $true
        Start-Preview
        return
    }

    if ([string]::IsNullOrWhiteSpace($script:ResolvedUrl)) {
        $script:ResolvedUrl = $UrlBox.Text.Trim()
    }

    $root = $OutputBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($root)) { $root = $DefaultOutput }
    if (-not (Test-Path $root)) { New-Item -ItemType Directory -Path $root -Force | Out-Null }

    $safeAlbum = Sanitize-FileName $script:AlbumTitle
    $script:AlbumFolder = Join-Path $root $safeAlbum
    New-Item -ItemType Directory -Path $script:AlbumFolder -Force | Out-Null

    # Snapshot existing Opus files so post-download tagging can target only
    # newly-created files during sync runs.
    $script:NewFilesBeforeRun = @{}
    Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $script:NewFilesBeforeRun[$_.FullName.ToLowerInvariant()] = $true
    }

    $script:DownloadedThisRun = 0
    $script:SkippedThisRun = 0
    $script:FailedThisRun = New-Object System.Collections.Generic.List[object]
    $script:FailedReportPath = Join-Path $script:AlbumFolder "OpusBox-Failed-Tracks.txt"
    $script:WatchdogRestarts = 0
    $script:WatchdogRestartPending = $false
    $script:LastArchiveCount = 0
    $script:LastProgressTime = Get-Date

    $SaveLocationText.Text = $script:AlbumFolder
    $script:CurrentTrack = 0
    $OverallProgress.IsIndeterminate = $false
    $OverallProgress.Value = 0
    $TrackStatusText.Text = "0 of $($script:TrackCount) complete"
    Set-Busy $true
    Set-Status "Downloading" "Downloading with resume protection, retry limits, and a 20-second network timeout." "Downloading"
    $TrackStatusText.Text = "Starting…"
    Write-Log "Output folder: $script:AlbumFolder"

    $archiveFile = Join-Path $script:AlbumFolder ".opusbox-download-archive.txt"
    $script:ArchiveFile = $archiveFile

    $downloadArgs = @(
        "--yes-playlist",
        "--ignore-errors",
        "--newline",

        # Resume / anti-stall behavior for large playlists
        "--download-archive", $archiveFile,
        "--retries", "3",
        "--fragment-retries", "3",
        "--socket-timeout", "20",

        "--extract-audio",
        "--audio-format", "opus",
        "--embed-metadata",
        "--no-embed-thumbnail",
        "--output", (Join-Path $script:AlbumFolder "%(playlist_index)02d - %(title)s.%(ext)s")
    )

    if ($DefaultFfmpeg -and (Test-Path $DefaultFfmpeg)) {
        $downloadArgs += @("--ffmpeg-location", (Split-Path $DefaultFfmpeg -Parent))
    }

    Write-Log "Downloading from: $script:ResolvedUrl"
    Write-Log "Resume archive: $archiveFile"
    Write-Log "Retry policy: 3 retries / 3 fragment retries / 20s socket timeout"
    Write-Log "Previously completed items in the archive will be skipped automatically."
    $downloadArgs += $script:ResolvedUrl
    $script:DownloadArgs = @($downloadArgs)
    $script:LastArchiveCount = Get-ArchiveCompletedCount
    $script:LastProgressTime = Get-Date
    Start-BackgroundCommand -Mode "download" -Exe $YtDlpBox.Text -CommandArgs $script:DownloadArgs
}

function Start-Picard {
    if (-not [bool]$AutoTagCheck.IsChecked) {
        Finish-All
        return
    }

    # Album lookup is great for actual albums, but a 1000-track favorites
    # playlist should never be clustered as one release. Large playlists are
    # downloaded normally and can be fingerprint-tagged later in safe batches.
    if ($script:TrackCount -gt $script:LargePlaylistCutoff) {
        $OverallProgress.IsIndeterminate = $false
        $OverallProgress.Value = 100
        $TrackStatusText.Text = "Download complete"
        Set-Status "Large playlist downloaded" "Picard album matching was skipped for $($script:TrackCount) tracks. Use Tag Existing Music to fingerprint-tag them in batches." "Ready to batch tag"
        Write-Log "Large playlist detected ($($script:TrackCount) tracks). Skipping album clustering in Picard."
        Write-Log "Use Tag Existing Music for batched AcoustID scanning."
        Set-Busy $false

        if ([bool]$OpenFolderCheck.IsChecked -and (Test-Path $script:AlbumFolder)) {
            Start-Process explorer.exe -ArgumentList @($script:AlbumFolder)
        }
        return
    }

    if (-not (Test-Path $PicardBox.Text)) {
        $AdvancedExpander.IsExpanded = $true
        Set-Status "Download complete" "The Opus files are ready, but Picard.exe was not found. Set the Picard path and tag manually." "Needs Picard"
        Write-Log "Picard not found. Audio download is complete."
        Set-Busy $false
        return
    }

    Set-Status "Tagging with Picard" "Clustering the album, looking it up on MusicBrainz, and saving matched tags." "Tagging"
    $OverallProgress.IsIndeterminate = $true
    $TrackStatusText.Text = "MusicBrainz lookup…"
    Write-Log "Starting MusicBrainz Picard automation."

    # Picard officially supports sequential -e commands.
    # Pause allows network lookup / cover-art work to settle before SAVE_MATCHED.
    $picardArgs = @(
        "-e", "LOAD `"$script:AlbumFolder`"",
        "-e", "CLUSTER",
        "-e", "LOOKUP_CLUSTERED",
        "-e", "PAUSE 12",
        "-e", "SAVE_MATCHED",
        "-e", "REMOVE_SAVED",
        "-e", "REMOVE_EMPTY",
        "-e", "SHOW"
    )

    try {
        Start-Process -FilePath $PicardBox.Text -ArgumentList $picardArgs | Out-Null
        # Picard command dispatch is asynchronous; give it a visual completion state
        # without blocking the UI. The files remain visible if a match needs review.
        $script:PicardFinishAt = (Get-Date).AddSeconds(15)
        $script:JobMode = "picardwait"
    } catch {
        Write-Log "Picard launch failed: $($_.Exception.Message)"
        Set-Status "Picard error" $_.Exception.Message "Error"
        Set-Busy $false
    }
}

function Finish-All {
    $OverallProgress.IsIndeterminate = $false
    $OverallProgress.Value = 100
    $TrackStatusText.Text = "Complete"
    Set-Status "Album ready" "Download and tagging workflow finished." "Complete"
    Write-Log "Finished."
    Set-Busy $false

    if ([bool]$OpenFolderCheck.IsChecked -and (Test-Path $script:AlbumFolder)) {
        Start-Process explorer.exe -ArgumentList @($script:AlbumFolder)
    }
}

function Process-ResolveResult {
    param([string[]]$Lines)

    $Lines | ForEach-Object { Write-Log $_ }
    $all = ($Lines -join "`n")

    $m = [regex]::Match(
        $all,
        'Redirecting to\s+(https://www\.youtube\.com/[^\s]+)',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    if (-not $m.Success) {
        $Lines | ForEach-Object { Write-Log $_ }
        throw "yt-dlp did not return a redirected YouTube URL."
    }

    $redirected = $m.Groups[1].Value.Trim().TrimEnd('.', ',', ';', ')')
    $script:ResolvedUrl = $redirected

    Write-Log "Redirected URL captured."
    Write-Log "Using: $redirected"

    # Show the exact URL yt-dlp gave us.
    $UrlBox.Text = $redirected
    $UrlBox.CaretIndex = $UrlBox.Text.Length

    # TextChanged may clear this while the textbox is focused.
    $script:ResolvedUrl = $redirected
    $script:PendingPreviewAfterResolve = $false

    Set-Busy $false
    $OverallProgress.IsIndeterminate = $false

    # Continue through the standard OpusBox flow using the new URL.
    Start-Preview
}

function Process-PreviewResult {
    param([string[]]$Lines)

    $joined = ($Lines | Where-Object { $_ -notmatch "^__OPUSBOX_EXITCODE__=" }) -join "`n"
    try {
        $info = $joined | ConvertFrom-Json
    } catch {
        throw "yt-dlp did not return valid playlist information. Open View log for details."
    }

    $title = [string]$info.title
    if ([string]::IsNullOrWhiteSpace($title)) { $title = [string]$info.playlist_title }
    if ([string]::IsNullOrWhiteSpace($title)) { $title = "YouTube Album" }
    $script:AlbumTitle = $title

    $entries = @($info.entries)
    $script:TrackCount = $entries.Count
    $script:Tracks = @()

    $i = 1
    foreach ($entry in $entries) {
        $t = [string]$entry.title
        if ([string]::IsNullOrWhiteSpace($t)) { $t = "Track $i" }
        $script:Tracks += [PSCustomObject]@{
            Index = $i.ToString("00")
            Title = $t
        }
        $i++
    }

    $thumb = ""
    if ($info.thumbnails) {
        $thumbs = @($info.thumbnails)
        if ($thumbs.Count -gt 0) { $thumb = [string]$thumbs[-1].url }
    }
    if ([string]::IsNullOrWhiteSpace($thumb) -and $entries.Count -gt 0 -and $entries[0].thumbnails) {
        $et = @($entries[0].thumbnails)
        if ($et.Count -gt 0) { $thumb = [string]$et[-1].url }
    }
    $script:AlbumThumb = $thumb

    $AlbumTitleText.Text = $script:AlbumTitle
    $AlbumMetaText.Text = "YouTube playlist • ready to download"
    $TrackCountBadge.Text = "$($script:TrackCount) tracks"
    $TrackList.ItemsSource = $script:Tracks
    Set-Cover $script:AlbumThumb
    $OverallProgress.IsIndeterminate = $false
    $OverallProgress.Value = 0
    $TrackStatusText.Text = "Ready"
    Set-Status "Album loaded" "Everything looks ready. Hit Download & Tag." "Ready"
    Write-Log "Loaded '$($script:AlbumTitle)' with $($script:TrackCount) track(s)."

    Set-Busy $false

    if ($script:PendingDownload) {
        $script:PendingDownload = $false
        Start-Download
    }
}



function Get-ArchiveCompletedCount {
    $completed = 0

    if (-not [string]::IsNullOrWhiteSpace($script:ArchiveFile) -and (Test-Path $script:ArchiveFile)) {
        try {
            $completed = @(
                Get-Content -Path $script:ArchiveFile -ErrorAction SilentlyContinue |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            ).Count
        } catch {}
    }

    if ($completed -eq 0 -and (Test-Path $script:AlbumFolder)) {
        try {
            $completed = @(Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue).Count
        } catch {}
    }

    return [Math]::Min($completed, [Math]::Max(0, $script:TrackCount))
}

function Start-DownloadProcessOnly {
    if (-not $script:DownloadArgs -or $script:DownloadArgs.Count -eq 0) {
        throw "Download arguments are not available for watchdog restart."
    }

    $script:WatchdogRestartPending = $false
    $script:LastArchiveCount = Get-ArchiveCompletedCount
    $script:LastProgressTime = Get-Date

    Write-Log "Watchdog restart $($script:WatchdogRestarts) of $($script:WatchdogMaxRestarts): resuming from download archive."
    Set-Status "Restarting stalled download" "yt-dlp stopped making progress, so OpusBox restarted it automatically. Completed tracks will be skipped from the archive." "Restarting"

    Start-BackgroundCommand -Mode "download" -Exe $YtDlpBox.Text -CommandArgs $script:DownloadArgs
}

function Update-LiveDownloadProgress {
    if ($script:JobMode -ne "download") { return }
    if ($script:TrackCount -le 0) { return }

    $completed = Get-ArchiveCompletedCount

    # Any completed-track count change is a watchdog heartbeat.
    if ($completed -ne $script:LastArchiveCount) {
        $script:LastArchiveCount = $completed
        $script:LastProgressTime = Get-Date
    }

    $pct = ($completed / [double]$script:TrackCount) * 100.0
    $OverallProgress.IsIndeterminate = $false
    $OverallProgress.Value = $pct
    $TrackStatusText.Text = "$completed of $($script:TrackCount) complete"

    $elapsed = ((Get-Date) - $script:LastProgressTime).TotalSeconds
    $remaining = [Math]::Max(0, $script:WatchdogStallSeconds - [int]$elapsed)

    if ($completed -gt 0) {
        $StatusTitle.Text = "Downloading"
        $StatusDetail.Text = "$completed / $($script:TrackCount) tracks complete ($([Math]::Round($pct, 1))%)"
        $FooterState.Text = "$completed / $($script:TrackCount)"
    }

    try {
        $latest = Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending |
                  Select-Object -First 1
        if ($latest) {
            $StatusDetail.Text = "$completed / $($script:TrackCount) tracks complete • Latest: $($latest.BaseName)"
        }
    } catch {}

    # OpusBox-level watchdog. If the archive count hasn't moved for three minutes,
    # kill yt-dlp and let the download-archive resume logic restart it.
    if (-not $script:WatchdogRestartPending -and
        $elapsed -ge $script:WatchdogStallSeconds) {

        if ($script:WatchdogRestarts -lt $script:WatchdogMaxRestarts) {
            $script:WatchdogRestarts++
            $script:WatchdogRestartPending = $true

            Write-Log "WATCHDOG: No completed track for $($script:WatchdogStallSeconds) seconds."
            Write-Log "WATCHDOG: Killing stalled yt-dlp process; automatic restart $($script:WatchdogRestarts) of $($script:WatchdogMaxRestarts)."
            Set-Status "Stall detected" "No track completed for 3 minutes. Restarting yt-dlp automatically…" "Watchdog"

            try {
                if ($script:CurrentProcess -and -not $script:CurrentProcess.HasExited) {
                    $script:CurrentProcess.Kill()
                }
            } catch {
                Write-Log "WATCHDOG: Could not kill yt-dlp: $($_.Exception.Message)"
                $script:WatchdogRestartPending = $false
                $script:LastProgressTime = Get-Date
            }
        }
        else {
            Write-Log "WATCHDOG: Maximum automatic restarts reached."
            Set-Status "Repeated stall" "The download stalled after $($script:WatchdogMaxRestarts) automatic restarts. OpusBox stopped retrying so it cannot loop forever." "Needs attention"

            if ($script:FailedThisRun.Count -eq 0 -or
                $script:FailedThisRun[$script:FailedThisRun.Count - 1].Reason -notmatch "watchdog") {

                $script:FailedThisRun.Add([PSCustomObject]@{
                    Index  = $completed + 1
                    Title  = if (($completed + 1) -le $script:Tracks.Count) { [string]$script:Tracks[$completed].Title } else { "" }
                    Reason = "OpusBox watchdog: no completed track for 3 minutes after $($script:WatchdogMaxRestarts) automatic restarts."
                })
            }

            try {
                if ($script:CurrentProcess -and -not $script:CurrentProcess.HasExited) {
                    $script:CurrentProcess.Kill()
                }
            } catch {}
        }
    }
}

function Process-DownloadLine {
    param([string]$Line)
    Write-Log $Line

    if ($Line -match "has already been recorded in the archive") {
        $script:SkippedThisRun++
        $TrackStatusText.Text = "Skipping completed track"
        $StatusDetail.Text = "Already downloaded earlier — continuing automatically."
        return
    }

    if ($Line -match "\[download\]\s+Downloading item\s+(\d+)\s+of\s+(\d+)") {
        $script:CurrentTrack = [int]$matches[1]
        $total = [int]$matches[2]
        if ($total -gt 0) {
            $pct = (($script:CurrentTrack - 1) / $total) * 100
            $OverallProgress.Value = [Math]::Max(0, [Math]::Min(99, $pct))
        }
        $TrackStatusText.Text = "Track $($script:CurrentTrack) of $total"
        if ($script:CurrentTrack -le $script:Tracks.Count) {
            $StatusDetail.Text = "Downloading $($script:Tracks[$script:CurrentTrack - 1].Title)"
        }
        return
    }

    if ($Line -match "\[download\]\s+(\d+(?:\.\d+)?)%") {
        $filePct = [double]$matches[1]
        $total = [Math]::Max(1, $script:TrackCount)
        $overall = (([Math]::Max(0, $script:CurrentTrack - 1) + ($filePct / 100.0)) / $total) * 100
        $OverallProgress.Value = [Math]::Max(0, [Math]::Min(99, $overall))
        return
    }

    if ($Line -match "100\.0%|100%") {
        $script:DownloadedThisRun++
        return
    }

    # Capture useful yt-dlp failures for the end-of-run report.
    if ($Line -match "ERROR:\s*(.+)$") {
        $reason = $matches[1].Trim()

        # Ignore the recurring virtual_file.log noise because it often does not
        # represent a failed track.
        if ($reason -match "virtual_file\.log") {
            return
        }

        $trackTitle = ""
        if ($script:CurrentTrack -gt 0 -and $script:CurrentTrack -le $script:Tracks.Count) {
            $trackTitle = [string]$script:Tracks[$script:CurrentTrack - 1].Title
        }

        $script:FailedThisRun.Add([PSCustomObject]@{
            Index  = $script:CurrentTrack
            Title  = $trackTitle
            Reason = $reason
        })
        return
    }
}

function Write-FailedTrackReport {
    if ([string]::IsNullOrWhiteSpace($script:FailedReportPath)) { return }

    if ($script:FailedThisRun.Count -eq 0) {
        try { Remove-Item $script:FailedReportPath -Force -ErrorAction SilentlyContinue } catch {}
        return
    }

    $report = New-Object System.Collections.Generic.List[string]
    $report.Add("OpusBox Failed Tracks")
    $report.Add("=====================")
    $report.Add("Generated: $(Get-Date)")
    $report.Add("")
    $report.Add("Failed items: $($script:FailedThisRun.Count)")
    $report.Add("")

    foreach ($f in $script:FailedThisRun) {
        $label = if ($f.Index -gt 0) { "Track $($f.Index)" } else { "Track" }
        if (-not [string]::IsNullOrWhiteSpace([string]$f.Title)) {
            $label += " - $($f.Title)"
        }
        $report.Add($label)
        $report.Add("Reason: $($f.Reason)")
        $report.Add("")
    }

    $report | Set-Content -Path $script:FailedReportPath -Encoding UTF8
    Write-Log "Failed-track report written: $script:FailedReportPath"
}

function Get-NewFilesForTagging {
    $newFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]

    Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue | Sort-Object FullName | ForEach-Object {
        $key = $_.FullName.ToLowerInvariant()
        if (-not $script:NewFilesBeforeRun.ContainsKey($key)) {
            $newFiles.Add($_)
        }
    }

    return @($newFiles)
}

function Start-AutomaticBatchTagging {
    param([System.IO.FileInfo[]]$Files)

    if (-not [bool]$AutoTagCheck.IsChecked) {
        Finish-DownloadWorkflow $Files.Count 0
        return
    }

    if ($Files.Count -eq 0) {
        Finish-DownloadWorkflow 0 0
        return
    }

    if (-not (Test-Path $PicardBox.Text)) {
        Write-Log "Picard not found; skipping post-download tagging."
        Finish-DownloadWorkflow $Files.Count 0
        return
    }

    $batchSize = $script:TagBatchSize
    $waitSeconds = $script:TagWaitSeconds
    $batchCount = [Math]::Ceiling($Files.Count / [double]$batchSize)

    $commands = New-Object System.Collections.Generic.List[string]
    $commands.Add("# Generated by OpusBox automatic post-download tagging")
    $commands.Add("SHOW")

    for ($offset = 0; $offset -lt $Files.Count; $offset += $batchSize) {
        $batchNumber = [int]($offset / $batchSize) + 1
        $end = [Math]::Min($offset + $batchSize - 1, $Files.Count - 1)

        $commands.Add("")
        $commands.Add("# Batch $batchNumber of $batchCount")
        $commands.Add("REMOVE_ALL")

        for ($i = $offset; $i -le $end; $i++) {
            $safePath = $Files[$i].FullName.Replace('"', '')
            $commands.Add("LOAD `"$safePath`"")
        }

        $commands.Add("SCAN")
        $commands.Add("PAUSE $waitSeconds")
        $commands.Add("SAVE_MATCHED")
        $commands.Add("PAUSE 3")
        $commands.Add("REMOVE_SAVED")
        $commands.Add("REMOVE_EMPTY")
        $commands.Add("REMOVE_UNCLUSTERED")
    }

    $commands.Add("")
    $commands.Add("SHOW")

    $commandDir = Join-Path $env:APPDATA "OpusBox"
    if (-not (Test-Path $commandDir)) {
        New-Item -ItemType Directory -Path $commandDir -Force | Out-Null
    }

    $commandFile = Join-Path $commandDir ("picard-auto-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".txt")
    $commands | Set-Content -Path $commandFile -Encoding UTF8

    Set-Status "Batch tagging new music" "Sending only the newly downloaded files to Picard in $batchCount batch(es)." "Tagging"
    $TrackStatusText.Text = "$($Files.Count) new file(s) queued for tagging"
    Write-Log "Automatic batch tagging: $($Files.Count) new file(s), $batchCount batch(es)."

    $picardArgs = @(
        "-e", "FROM_FILE `"$commandFile`"",
        "-e", "SHOW"
    )

    Start-Process -FilePath $PicardBox.Text -ArgumentList $picardArgs | Out-Null

    # Picard runs independently. We can give the user a clean completion summary
    # for the download phase and indicate that tagging was queued.
    Finish-DownloadWorkflow $Files.Count $batchCount
}

function Finish-DownloadWorkflow {
    param(
        [int]$NewFiles,
        [int]$TagBatches
    )

    Write-FailedTrackReport

    $OverallProgress.IsIndeterminate = $false
    $OverallProgress.Value = 100
    $TrackStatusText.Text = "Complete"

    $summary = "Downloaded/new: $NewFiles"
    if ($script:SkippedThisRun -gt 0) {
        $summary += " • Skipped: $($script:SkippedThisRun)"
    }
    if ($script:FailedThisRun.Count -gt 0) {
        $summary += " • Failed: $($script:FailedThisRun.Count)"
    }
    if ($TagBatches -gt 0) {
        $summary += " • Picard batches queued: $TagBatches"
    }

    Set-Status "Sync complete" $summary "Complete"
    Write-Log "Sync summary: $summary"

    if ($script:FailedThisRun.Count -gt 0) {
        Write-Log "Review failures at: $script:FailedReportPath"
    }

    Set-Busy $false

    if ([bool]$OpenFolderCheck.IsChecked -and (Test-Path $script:AlbumFolder)) {
        Start-Process explorer.exe -ArgumentList @($script:AlbumFolder)
    }
}

# ----------------------------
# Timer / process handling
# ----------------------------
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(200)
$timer.Add_Tick({
    if ($script:JobMode -eq "picardwait") {
        if ($script:PicardFinishAt -and (Get-Date) -ge $script:PicardFinishAt) {
            $script:JobMode = ""
            Finish-All
        }
        return
    }

    if (-not $script:CurrentProcess) { return }

    if (-not $script:CurrentProcess.HasExited) {
        if ($script:JobMode -eq "resolve") {
            $FooterState.Text = "Resolving YouTube Music link…"
        }
        elseif ($script:JobMode -eq "preview") {
            $FooterState.Text = "Reading album…"
        }
        elseif ($script:JobMode -eq "download") {
            Update-LiveDownloadProgress
        }
        return
    }

    try { $script:CurrentProcess.WaitForExit() } catch {}

    $mode = $script:JobMode
    $exitCode = $script:CurrentProcess.ExitCode

    $stdout = ""
    $stderr = ""
    try {
        if ($script:StdoutTask) { $stdout = [string]$script:StdoutTask.GetAwaiter().GetResult() }
    } catch {}
    try {
        if ($script:StderrTask) { $stderr = [string]$script:StderrTask.GetAwaiter().GetResult() }
    } catch {}

    $stdoutLines = @()
    $stderrLines = @()

    if (-not [string]::IsNullOrWhiteSpace($stdout)) {
        $stdoutLines = @($stdout -split "\r?\n" | Where-Object { $_ -ne "" })
    }

    if (-not [string]::IsNullOrWhiteSpace($stderr)) {
        $stderrLines = @($stderr -split "\r?\n" | Where-Object { $_ -ne "" })
    }

    $allLines = @($stdoutLines) + @($stderrLines)

    try { $script:CurrentProcess.Dispose() } catch {}
    $script:CurrentProcess = $null
    $script:StdoutTask = $null
    $script:StderrTask = $null
    $script:JobMode = ""

    # If the watchdog intentionally killed yt-dlp, do not treat that exit as a
    # completed/failed download. Restart the same command and let the archive skip
    # everything already finished.
    if ($mode -eq "download" -and $script:WatchdogRestartPending) {
        try {
            Start-DownloadProcessOnly
        }
        catch {
            $script:WatchdogRestartPending = $false
            Set-Status "Watchdog restart failed" $_.Exception.Message "Error"
            Write-Log "WATCHDOG ERROR: $($_.Exception.Message)"
            $LogExpander.IsExpanded = $true
            Set-Busy $false
        }
        return
    }

    try {
        if ($mode -eq "resolve") {
            # yt-dlp prints the YouTube Music redirect warning to stderr, so the
            # resolver intentionally sees both streams.
            if ($exitCode -ne 0) {
                $allLines | ForEach-Object { Write-Log $_ }
                throw "Could not resolve that YouTube Music link."
            }
            Process-ResolveResult $allLines
        }
        elseif ($mode -eq "preview") {
            # --dump-single-json writes JSON to stdout. Warnings/errors such as
            # virtual_file.log are written to stderr and MUST NOT be concatenated
            # with the JSON or ConvertFrom-Json will fail.
            if ($stderrLines.Count -gt 0) {
                $stderrLines | ForEach-Object { Write-Log $_ }
            }

            if ($exitCode -ne 0 -and $stdoutLines.Count -eq 0) {
                throw "Could not read that YouTube playlist."
            }

            Process-PreviewResult $stdoutLines
        }
        elseif ($mode -eq "download") {
            $allLines | ForEach-Object { Process-DownloadLine ([string]$_) }

            $opus = @(Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue)
            if ($opus.Count -eq 0) {
                throw "No Opus files were created. Open View log to see the yt-dlp error."
            }

            $newFiles = @(Get-NewFilesForTagging)
            $TrackStatusText.Text = "$($opus.Count) total file(s) in folder"
            Write-Log "Download finished: $($opus.Count) total Opus file(s), $($newFiles.Count) new this run."

            # For new downloads, always use the safe batch-tag workflow rather than
            # trying to cluster a giant mixed playlist as one album.
            Start-AutomaticBatchTagging $newFiles
        }
    }
    catch {
        $OverallProgress.IsIndeterminate = $false
        Set-Status "Something went wrong" $_.Exception.Message "Error"
        Write-Log "ERROR: $($_.Exception.Message)"
        $LogExpander.IsExpanded = $true
        Set-Busy $false
    }
})
$timer.Start()


function Show-TagLibraryWindow {
    if (-not (Test-Path $PicardBox.Text)) {
        $AdvancedExpander.IsExpanded = $true
        [System.Windows.MessageBox]::Show(
            "Picard.exe was not found. Set its path under Advanced settings first.",
            "OpusBox"
        )
        return
    }

    [xml]$tagXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="OpusBox - Tag Existing Music"
    Width="650"
    Height="520"
    MinWidth="600"
    MinHeight="480"
    WindowStartupLocation="CenterOwner"
    Background="#0B0D12"
    Foreground="#F5F7FB"
    FontFamily="Segoe UI">
    <Window.Resources>
        <SolidColorBrush x:Key="Panel" Color="#12151C"/>
        <SolidColorBrush x:Key="Border" Color="#272C38"/>
        <SolidColorBrush x:Key="Muted" Color="#8F98A8"/>
        <SolidColorBrush x:Key="Accent" Color="#8B5CF6"/>

        <Style TargetType="TextBox">
            <Setter Property="Foreground" Value="#F5F7FB"/>
            <Setter Property="Background" Value="#0F1218"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="CaretBrush" Value="White"/>
        </Style>

        <Style x:Key="TagPrimaryButton" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Background" Value="{StaticResource Accent}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="9" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="TagSecondaryButton" TargetType="Button">
            <Setter Property="Foreground" Value="#F5F7FB"/>
            <Setter Property="Background" Value="#1A1F29"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="8"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,18">
            <TextBlock Text="Tag Existing Music" FontSize="23" FontWeight="SemiBold"/>
            <TextBlock Text="Fingerprint mixed playlists in small Picard batches instead of treating them as one album."
                       Foreground="{StaticResource Muted}" Margin="0,5,0,0" TextWrapping="Wrap"/>
        </StackPanel>

        <Border Grid.Row="1" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="15" Margin="0,0,0,14">
            <StackPanel>
                <TextBlock Text="Music folder" FontWeight="SemiBold" Margin="0,0,0,7"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="10"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox x:Name="TagFolderBox" Grid.Column="0" Height="38"/>
                    <Button x:Name="TagBrowseButton" Grid.Column="2" Style="{StaticResource TagSecondaryButton}" Content="Browse"/>
                </Grid>
                <TextBlock x:Name="TagCountText" Text="Choose a folder containing .opus files."
                           Foreground="{StaticResource Muted}" FontSize="12" Margin="0,8,0,0"/>
            </StackPanel>
        </Border>

        <Grid Grid.Row="2" Margin="0,0,0,14">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="14"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="15">
                <StackPanel>
                    <TextBlock Text="Batch size" FontWeight="SemiBold"/>
                    <TextBox x:Name="BatchSizeBox" Text="25" Height="38" Margin="0,8,0,0"/>
                    <TextBlock Text="20–30 is a good range for Picard."
                               Foreground="{StaticResource Muted}" FontSize="11" Margin="0,6,0,0"/>
                </StackPanel>
            </Border>

            <Border Grid.Column="2" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="15">
                <StackPanel>
                    <TextBlock Text="Lookup wait / batch" FontWeight="SemiBold"/>
                    <TextBox x:Name="BatchWaitBox" Text="45" Height="38" Margin="0,8,0,0"/>
                    <TextBlock Text="Seconds Picard gets for Scan / AcoustID lookups."
                               Foreground="{StaticResource Muted}" FontSize="11" Margin="0,6,0,0"/>
                </StackPanel>
            </Border>
        </Grid>

        <Border Grid.Row="3" Background="#171B24" CornerRadius="10" Padding="13" Margin="0,0,0,14">
            <TextBlock x:Name="TagSummaryText"
                       Text="Picard will Scan each batch using AcoustID, save matched files, then move to the next batch. Unmatched files stay unchanged on disk."
                       TextWrapping="Wrap" FontSize="12" Foreground="#C8D0DC"/>
        </Border>

        <TextBox x:Name="TagLogBox" Grid.Row="4"
                 IsReadOnly="True"
                 AcceptsReturn="True"
                 VerticalScrollBarVisibility="Auto"
                 Background="#0D1016"
                 BorderBrush="{StaticResource Border}"
                 Foreground="#CBD2DE"
                 FontFamily="Consolas"
                 FontSize="11"
                 TextWrapping="Wrap"
                 Padding="10"/>

        <Grid Grid.Row="5" Margin="0,16,0,0">
            <TextBlock x:Name="TagFooterText" Text="Ready" Foreground="{StaticResource Muted}" VerticalAlignment="Center"/>
            <Button x:Name="TagStartButton" Style="{StaticResource TagPrimaryButton}" Content="Start Batch Tagging"
                    HorizontalAlignment="Right" MinWidth="160"/>
        </Grid>
    </Grid>
</Window>
"@

    $tagReader = New-Object System.Xml.XmlNodeReader $tagXaml
    $tagWindow = [Windows.Markup.XamlReader]::Load($tagReader)
    $tagWindow.Owner = $Window

    $tagFolderBox = $tagWindow.FindName("TagFolderBox")
    $tagBrowseButton = $tagWindow.FindName("TagBrowseButton")
    $tagCountText = $tagWindow.FindName("TagCountText")
    $batchSizeBox = $tagWindow.FindName("BatchSizeBox")
    $batchWaitBox = $tagWindow.FindName("BatchWaitBox")
    $tagSummaryText = $tagWindow.FindName("TagSummaryText")
    $tagLogBox = $tagWindow.FindName("TagLogBox")
    $tagFooterText = $tagWindow.FindName("TagFooterText")
    $tagStartButton = $tagWindow.FindName("TagStartButton")

    if (Test-Path $OutputBox.Text) {
        $tagFolderBox.Text = $OutputBox.Text
    }

    function Update-TagFolderSummary {
        $folder = $tagFolderBox.Text.Trim()
        if (-not (Test-Path $folder)) {
            $tagCountText.Text = "Folder not found."
            return
        }

        $files = @(Get-ChildItem -Path $folder -Filter "*.opus" -File -Recurse -ErrorAction SilentlyContinue)
        $tagCountText.Text = "$($files.Count) Opus file(s) found."
    }

    $tagBrowseButton.Add_Click({
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        if (Test-Path $tagFolderBox.Text) { $dlg.SelectedPath = $tagFolderBox.Text }

        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $tagFolderBox.Text = $dlg.SelectedPath
            Update-TagFolderSummary
        }
    })

    $tagFolderBox.Add_LostFocus({ Update-TagFolderSummary })

    $tagStartButton.Add_Click({
        try {
            $folder = $tagFolderBox.Text.Trim()
            if (-not (Test-Path $folder)) {
                throw "Choose a valid folder first."
            }

            $batchSize = 0
            if (-not [int]::TryParse($batchSizeBox.Text.Trim(), [ref]$batchSize) -or $batchSize -lt 1 -or $batchSize -gt 100) {
                throw "Batch size must be between 1 and 100."
            }

            $waitSeconds = 0
            if (-not [int]::TryParse($batchWaitBox.Text.Trim(), [ref]$waitSeconds) -or $waitSeconds -lt 5 -or $waitSeconds -gt 300) {
                throw "Lookup wait must be between 5 and 300 seconds."
            }

            $files = @(Get-ChildItem -Path $folder -Filter "*.opus" -File -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName)
            if ($files.Count -eq 0) {
                throw "No .opus files were found in that folder."
            }

            $batchCount = [Math]::Ceiling($files.Count / [double]$batchSize)

            $commands = New-Object System.Collections.Generic.List[string]
            $commands.Add("# Generated by OpusBox")
            $commands.Add("SHOW")

            for ($offset = 0; $offset -lt $files.Count; $offset += $batchSize) {
                $batchNumber = [int]($offset / $batchSize) + 1
                $end = [Math]::Min($offset + $batchSize - 1, $files.Count - 1)

                $commands.Add("")
                $commands.Add("# Batch $batchNumber of $batchCount")
                $commands.Add("REMOVE_ALL")

                for ($i = $offset; $i -le $end; $i++) {
                    $safePath = $files[$i].FullName.Replace('"', '')
                    $commands.Add("LOAD `"$safePath`"")
                }

                $commands.Add("SCAN")
                $commands.Add("PAUSE $waitSeconds")
                $commands.Add("SAVE_MATCHED")
                $commands.Add("PAUSE 3")
                $commands.Add("REMOVE_SAVED")
                $commands.Add("REMOVE_EMPTY")
                $commands.Add("REMOVE_UNCLUSTERED")
            }

            $commands.Add("")
            $commands.Add("SHOW")

            $commandDir = Join-Path $env:APPDATA "OpusBox"
            if (-not (Test-Path $commandDir)) {
                New-Item -ItemType Directory -Path $commandDir -Force | Out-Null
            }

            $commandFile = Join-Path $commandDir ("picard-batch-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".txt")
            $commands | Set-Content -Path $commandFile -Encoding UTF8

            $estimatedMinutes = [Math]::Ceiling(($batchCount * ($waitSeconds + 3)) / 60.0)

            $tagLogBox.AppendText("Files: $($files.Count)`r`n")
            $tagLogBox.AppendText("Batch size: $batchSize`r`n")
            $tagLogBox.AppendText("Batches: $batchCount`r`n")
            $tagLogBox.AppendText("Estimated minimum queue time: ~${estimatedMinutes} min`r`n")
            $tagLogBox.AppendText("Command file: $commandFile`r`n`r`n")
            $tagLogBox.AppendText("Sending batches to Picard...`r`n")

            $picardArgs = @(
                "-e", "FROM_FILE `"$commandFile`"",
                "-e", "SHOW"
            )

            Start-Process -FilePath $PicardBox.Text -ArgumentList $picardArgs | Out-Null

            $tagFooterText.Text = "Queued $batchCount batch(es) in Picard"
            $tagStartButton.IsEnabled = $false
            $tagStartButton.Content = "Queued"

            $tagSummaryText.Text = "Picard is processing $($files.Count) files in $batchCount batches. Matched files will be saved. Unmatched files remain unchanged on disk and are removed only from Picard's working pane before the next batch."

            Write-Log "Batch tagging started: $($files.Count) files, $batchCount batches of up to $batchSize."
        }
        catch {
            $tagFooterText.Text = "Error"
            $tagLogBox.AppendText("ERROR: $($_.Exception.Message)`r`n")
            [System.Windows.MessageBox]::Show($_.Exception.Message, "OpusBox")
        }
    })

    Update-TagFolderSummary
    [void]$tagWindow.ShowDialog()
}

# ----------------------------
# UI events
# ----------------------------
$TagLibraryButton.Add_Click({ Show-TagLibraryWindow })
$PreviewButton.Add_Click({ Start-Preview })
$DownloadButton.Add_Click({ Start-Download })

$UrlBox.Add_TextChanged({
    # New URL invalidates the cached album preview.
    if (-not $UrlBox.IsFocused) { return }
    $script:AlbumTitle = ""
    $script:ResolvedUrl = ""
    $script:Tracks = @()
})

$BrowseOutputButton.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if (Test-Path $OutputBox.Text) { $dlg.SelectedPath = $OutputBox.Text }
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $OutputBox.Text = $dlg.SelectedPath
        $SaveLocationText.Text = $OutputBox.Text
        Save-Settings
    }
})

$OutputBox.Add_LostFocus({ $SaveLocationText.Text = $OutputBox.Text; Save-Settings })
$YtDlpBox.Add_LostFocus({ Save-Settings; Update-ToolHealth })
$PicardBox.Add_LostFocus({ Save-Settings; Update-ToolHealth })
$AutoTagCheck.Add_Click({ Save-Settings })
$OpenFolderCheck.Add_Click({ Save-Settings })

$Window.Add_Closing({
    Save-Settings
    if ($script:CurrentProcess) {
        try {
            if (-not $script:CurrentProcess.HasExited) { $script:CurrentProcess.Kill() }
            $script:CurrentProcess.Dispose()
        } catch {}
    }
})

Load-Settings
[void]$Window.ShowDialog()
