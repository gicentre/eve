port module GalleryOther exposing (elmToJS)

import Html exposing (Html, div, pre)
import Html.Attributes exposing (id)
import Json.Encode
import Platform
import Vega exposing (..)


-- NOTE: All data sources in these examples originally provided at
-- https://vega.github.io/vega-datasets/
-- The examples themselves reproduce those at https://vega.github.io/vega/examples/


heatmap1 : Spec
heatmap1 =
    let
        colors =
            [ "Viridis"
            , "Magma"
            , "Inferno"
            , "Plasma"
            , "Blues"
            , "Greens"
            , "Greys"
            , "Purples"
            , "Reds"
            , "Oranges"
            , "BlueOrange"
            , "BrownBlueGreen"
            , "PurpleGreen"
            , "PinkYellowGreen"
            , "PurpleOrange"
            , "RedBlue"
            , "RedGrey"
            , "RedYellowBlue"
            , "RedYellowGreen"
            , "BlueGreen"
            , "BluePurple"
            , "GreenBlue"
            , "OrangeRed"
            , "PurpleBlueGreen"
            , "PurpleBlue"
            , "PurpleRed"
            , "RedPurple"
            , "YellowGreenBlue"
            , "YellowGreen"
            , "YellowOrangeBrown"
            , "YellowOrangeRed"
            ]

        ti =
            title (str "Seattle Annual Temperatures")
                [ tiAnchor Middle
                , tiFontSize (num 16)
                , tiFrame FrGroup
                , tiOffset (num 4)
                ]

        ds =
            dataSource
                [ data "temperature"
                    [ daUrl "https://vega.github.io/vega/data/seattle-temps.csv"
                    , daFormat [ CSV, parse [ ( "temp", FoNum ), ( "date", foDate "" ) ] ]
                    ]
                    |> transform
                        [ trFormula "hours(datum.date)" "hour" InitOnly
                        , trFormula "datetime(year(datum.date), month(datum.date), date(datum.date))" "day" InitOnly
                        , trFormula "(datum.temp - 32) / 1.8" "celsius" InitOnly
                        ]
                ]

        si =
            signals
                << signal "palette" [ siValue (vStr "Viridis"), siBind (iSelect [ inOptions (vStrs colors) ]) ]
                << signal "reverse" [ siValue (vBoo False), siBind (iCheckbox []) ]

        sc =
            scales
                << scale "xScale"
                    [ scType ScTime
                    , scDomain (doData [ daDataset "temperature", daField (field "day") ])
                    , scRange (raDefault RWidth)
                    ]
                << scale "yScale"
                    [ scType ScBand
                    , scDomain (doNums (nums [ 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 0, 1, 2, 3, 4, 5 ]))
                    , scRange (raDefault RHeight)
                    ]
                << scale "cScale"
                    [ scType ScSequential
                    , scRange (raScheme (strSignal "palette") [])
                    , scDomain (doData [ daDataset "temperature", daField (field "celsius") ])
                    , scReverse (booSignal "reverse")
                    , scZero (boo False)
                    , scNice NTrue
                    ]

        ax =
            axes
                << axis "xScale" SBottom [ axDomain (boo False), axTitle (str "Month"), axFormat "%b" ]
                << axis "yScale"
                    SLeft
                    [ axDomain (boo False)
                    , axTitle (str "Hour")
                    , axEncode
                        [ ( ELabels
                          , [ enUpdate
                                [ maText [ vSignal "datum.value === 0 ? 'Midnight' : datum.value === 12 ? 'Noon' : datum.value < 12 ? datum.value + ':00 am' : (datum.value - 12) + ':00 pm'" ]
                                ]
                            ]
                          )
                        ]
                    ]

        le =
            legends
                << legend
                    [ leFill "cScale"
                    , leType LGradient
                    , leTitle (str "Avg. Temp (°C)")
                    , leTitleFontSize (num 12)
                    , leTitlePadding (vNum 4)
                    , leGradientLength (numSignal "height - 16")
                    ]

        mk =
            marks
                << mark Rect
                    [ mFrom [ srData (str "temperature") ]
                    , mEncode
                        [ enEnter
                            [ maX [ vScale (field "xScale"), vField (field "day") ]
                            , maWidth [ vNum 5 ]
                            , maY [ vScale (field "yScale"), vField (field "hour") ]
                            , maHeight [ vScale (field "yScale"), vBand (num 1) ]
                            , maTooltip [ vSignal "timeFormat(datum.date, '%b %d %I:00 %p') + ': ' + datum.celsius + '°'" ]
                            ]
                        , enUpdate [ maFill [ vScale (field "cScale"), vField (field "celsius") ] ]
                        ]
                    ]
    in
    toVega
        [ width 800, height 500, ti, ds, si [], sc [], ax [], le [], mk [] ]


parallel1 : Spec
parallel1 =
    let
        --  TODO: Add config
        ds =
            dataSource
                [ data "cars"
                    [ daUrl "https://vega.github.io/vega/data/cars.json"
                    , daFormat [ JSON, parse [ ( "Year", foDate "%Y-%m-%d" ) ] ]
                    ]
                    |> transform
                        [ trFilter (expr "datum.Horsepower && datum.Miles_per_Gallon")
                        , trFormula "isNumber(datum.year) ? datum.year : year(datum.Year)" "Year" InitOnly
                        ]
                , data "fields" [ daValue (vStrs [ "Cylinders", "Displacement", "Weight_in_lbs", "Horsepower", "Acceleration", "Miles_per_Gallon", "Year" ]) ]
                ]

        dimensionScale fName =
            scale fName
                [ scType ScLinear
                , scRange (raDefault RHeight)
                , scDomain (doData [ daDataset "cars", daField (field fName) ])
                , scZero (boo False)
                , scNice NTrue
                ]

        sc =
            scales
                << scale "ord"
                    [ scType ScPoint
                    , scRange (raDefault RWidth)
                    , scDomain (doData [ daDataset "fields", daField (field "data") ])
                    , scRound (boo True)
                    ]
                << dimensionScale "Cylinders"
                << dimensionScale "Displacement"
                << dimensionScale "Weight_in_lbs"
                << dimensionScale "Horsepower"
                << dimensionScale "Acceleration"
                << dimensionScale "Miles_per_Gallon"
                << dimensionScale "Year"

        dimensionAxis sName =
            axis sName
                SLeft
                [ axTitle (str sName)
                , axOffset (vObject [ vStr sName, vScale (field "ord"), vMultiply (vNum -1) ])
                , axZIndex (num 1)
                ]

        ax =
            axes
                << dimensionAxis "Cylinders"
                << dimensionAxis "Displacement"
                << dimensionAxis "Weight_in_lbs"
                << dimensionAxis "Horsepower"
                << dimensionAxis "Acceleration"
                << dimensionAxis "Miles_per_Gallon"
                << dimensionAxis "Year"

        mk =
            marks
                << mark Group [ mFrom [ srData (str "cars") ], mGroup [ nestedMk [] ] ]

        nestedMk =
            marks
                << mark Line
                    [ mFrom [ srData (str "fields") ]
                    , mEncode
                        [ enEnter
                            [ maX [ vScale (field "ord"), vField (field "data") ]
                            , maY [ vScale (fDatum (field "data")), vField (fParent (fDatum (field "data"))) ]
                            , maStroke [ vStr "steelblue" ]
                            , maStrokeWidth [ vNum 1.01 ]
                            , maStrokeOpacity [ vNum 0.3 ]
                            ]
                        ]
                    ]
    in
    toVega
        [ width 700, height 400, padding 5, ds, sc [], ax [], mk [] ]


sourceExample : Spec
sourceExample =
    parallel1



{- This list comprises the specifications to be provided to the Vega runtime. -}


mySpecs : Spec
mySpecs =
    combineSpecs
        [ ( "heatmap1", heatmap1 )
        , ( "parallel1", parallel1 )
        ]



{- ---------------------------------------------------------------------------
   The code below creates an Elm module that opens an outgoing port to Javascript
   and sends both the specs and DOM node to it.
   This is used to display the generated Vega specs for testing purposes.
-}


main : Program Never Spec msg
main =
    Html.program
        { init = ( mySpecs, elmToJS mySpecs )
        , view = view
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }



-- View


view : Spec -> Html msg
view spec =
    div []
        [ div [ id "specSource" ] []
        , pre []
            [ Html.text (Json.Encode.encode 2 sourceExample) ]
        ]


port elmToJS : Spec -> Cmd msg
