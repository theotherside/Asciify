# Copyright 2019 Tobias Heilig
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice, this list
# of conditions and the following disclaimer in the documentation and/or other materials
# provided with the distribution.
# 3. Neither the name of the copyright holder nor the names of its contributors may be used
# to endorse or promote products derived from this software without specific prior written
# permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#requires -version 5

using namespace System.Drawing

Add-Type -AssemblyName System.Drawing


<#
    .SYNOPSIS
    Convert image to ascii.

    .DESCRIPTION
    Convert any image to ascii picture by representing each pixels grayscale value as an ascii character.
    The higher the grayscale value the more space the corresponding ascii character fills. Before being
    processed the image will be cropped in memory to fit the consoles width or height.

    .PARAMETER Path
    The path to the image to process.

    .PARAMETER Resolution
    The amount of different ascii characters the grayscale values will be assigned to. The bigger the
    console window and the smaller the font size a higher resolution tends to look better when the image
    is also of high resolution.

    .PARAMETER FitConsoleHeight
    Whether the output ascii picture should fit the console height instead of width.

    .PARAMETER AdjustBackgroundColor
    Whether the output ascii picture should be printed out colored white on black. Use this on light
    console backgrounds for better results.

    .OUTPUTS
    A string of ascii characters representing each pixels grayscale value from the original image. Each
    pixel row is separated by a newline character. When the -AdjustBackgroundColor Parameter is specified
    the result will be printed out using Write-Host.

    .COMPONENT
    GDI+

    .EXAMPLE
    Convert-ImageToAscii C:\Users\Bobby\Pictures\bobby-fischer.jpg -AdjustBackgroundColor

    .EXAMPLE
    Convert-ImageToAscii -Path C:\Users\Bobby\Pictures\bobby-fischer.jpg -Resolution Mid -FitConsoleHeight

    .EXAMPLE
    i2a .\bobby-fischer.jpg
#>
function Convert-ImageToAscii
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateScript({Test-Path $_})]
        [string]
        $Path,

        [ValidateSet('Low', 'Mid', 'High')]
        [string]
        $Resolution='Low',

        [switch]
        $FitConsoleHeight,

        [switch]
        $AdjustBackgroundColor
    )

    $img = [Image]::FromFile($Path)

    if (-not $FitConsoleHeight)
    {
        [int]$w = $Host.UI.RawUI.WindowSize.Width/2 - 1
        [int]$h = $Host.UI.RawUI.WindowSize.Width/2/($img.Width/$img.Height)
    }
    else
    {
        [int]$w = $Host.UI.RawUI.WindowSize.Height*($img.Width/$img.Height)
        [int]$h = $Host.UI.RawUI.WindowSize.Height - 4
    }

    $bmp = New-Object Bitmap $w, $h
    $bmp.SetResolution($img.HorizontalResolution, $img.VerticalResolution)

    $rec = New-Object Rectangle 0, 0, $w, $h
    $wrapMode = New-Object Imaging.ImageAttributes
    $wrapMode.SetWrapMode([Drawing2D.WrapMode]::TileFlipXY)

    $graphics                    = [Graphics]::FromImage($bmp)
    $graphics.CompositingMode    = [Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode  = [Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode      = [Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode    = [Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($img, $rec, 0, 0, $img.Width, $img.Height, [GraphicsUnit]::Pixel, $wrapMode)

    $chars = @{
        'Low'  = " .o#@"
        'Mid'  = " .,:+*#%@"
        'High' = " .,:;~+?txXCmo#%@"
    }

    foreach ($y in 0..($bmp.Height-1))
    {
        foreach ($x in 0..($bmp.Width-1))
        {
            $p = $bmp.GetPixel($x, $y)
            $symbol = "$($chars[$Resolution][[Math]::Floor((($p.R+$p.G+$p.B)/3)/(256/$chars[$Resolution].Length))])" * 2
            $ascii += $symbol
        }
        
        $ascii += "`n"
    }

    if ($AdjustBackgroundColor)
    {
        Write-Host $ascii -BackgroundColor Black -ForegroundColor White
    }
    else
    {
        $ascii    
    }

    $wrapMode.Dispose()
    $graphics.Dispose()
    $img.Dispose()
}

New-Alias -Name i2a -Value Convert-ImageToAscii
