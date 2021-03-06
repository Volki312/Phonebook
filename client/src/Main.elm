module Main exposing (Contact, Model, Msg(..), checkContact, contactDecoder, contactListDecoder, init, main, readContacts, subscriptions, update, view, viewBody)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder, field, map4)
import Json.Encode as JE exposing (Value, encode, object)
import List



--import Debug
-- MAIN


main =
    Browser.document
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Contact =
    { id_ : Int
    , name : String
    , number : String
    , email : String
    }


type alias Form =
    { name : String
    , number : String
    , email : String
    }


type Status
    = Failure
    | Loading
    | Success (List Contact)


type alias Model =
    { status : Status
    , form : Form
    , api : String
    }


init : String -> ( Model, Cmd Msg )
init api =
    --( { status = Loading, form = { name = "", number = "", email = "" }, api = "https://simplephonebook.herokuapp.com/contacts/" }, readContacts "https://simplephonebook.herokuapp.com/contacts/" )
    ( Model Loading (Form "" "" "") api, readContacts api )



-- UPDATE


type Msg
    = LoadContacts
    | GotContacts (Result Http.Error (List Contact))
    | Uploaded (Result Http.Error ())
    | Name String
    | Number String
    | Email String
    | SubmitForm Contact String
    | DeleteContact Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        form =
            model.form
    in
    case msg of
        LoadContacts ->
            ( { model | status = Loading }, readContacts model.api )

        GotContacts result ->
            case result of
                Ok contacts ->
                    ( { model | status = Success contacts }, Cmd.none )

                Err _ ->
                    ( { model | status = Failure }, Cmd.none )

        Uploaded result ->
            case result of
                Ok _ ->
                    ( { model | status = Loading }, readContacts model.api )

                Err _ ->
                    ( { model | status = Failure }, Cmd.none )

        SubmitForm contact api ->
            ( { model | form = Form "" "" "" }
            , Http.post
                { url = api
                , body = Http.jsonBody (contactEncoder contact)
                , expect = Http.expectWhatever Uploaded
                }
            )

        DeleteContact id ->
            ( model
            , Http.request
                { method = "DELETE"
                , headers = []
                , url = model.api ++ String.fromInt id
                , body = Http.emptyBody
                , expect = Http.expectWhatever Uploaded
                , timeout = Nothing
                , tracker = Nothing
                }
            )

        Name name ->
            ( { model | form = { form | name = name } }, Cmd.none )

        Number number ->
            ( { model | form = { form | number = number } }, Cmd.none )

        Email email ->
            ( { model | form = { form | email = email } }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Phonebook"
    , body =
        [ div [ id "main" ]
            [ h1 [] [ text "Phone book" ]
            , viewBody model
            ]
        ]
    }


viewBody : Model -> Html Msg
viewBody model =
    case model.status of
        Failure ->
            div []
                [ p [] [ text "Couldn't load contacts for some reason." ]
                , button [ onClick LoadContacts ] [ text "Try again" ]

                --, button [ preventDefaultOn "click" (JD.map alwaysPreventDefault (JD.succeed LoadContacts)) ] [ text "Try again" ]
                ]

        Loading ->
            text "Loading..."

        Success contacts ->
            div [ id "phonebook" ]
                [ viewForm model.form model.api
                , div [ id "phonebook__contacts" ] (List.map viewContact contacts)
                ]


viewContact : Contact -> Html Msg
viewContact contact =
    div [ class "contact" ]
        [ div [ class "contact__header" ]
            [ h2 [ class "contact__name" ] [ text contact.name ]
            , button [ class "contact__button contact__button--dial" ] [ a [ href ("tel:+" ++ contact.number) ] [ text "DIAL" ] ]

            --, button [ class "contact__button contact__button--delete", preventDefaultOn "click" (JD.map alwaysPreventDefault (JD.succeed (DeleteContact contact.id_))) ] [ text "DEL" ]
            , button [ class "contact__button contact__button--delete", onClick (DeleteContact contact.id_) ] [ text "DEL" ]
            ]
        , p [ class "contact__number" ] [ a [] [ text contact.number ] ]
        , p [ class "contact__email" ] [ text contact.email ]
        ]


viewForm : Form -> String -> Html Msg
viewForm form api =
    --let
    --    form =
    --        model.form
    --in
    Html.form [ id "phonebook__form" ]
        [ viewInput "Name*: " "text" "phonebook__name" " Josip" form.name Name
        , viewInput "Number*: " "text" "phonebook__number" " 098662672" form.number Number
        , viewInput "Email: " "text" "phonebook__email" " josip312@hotmail.com" form.email Email

        --, button [ id "phonebook__button", onClick (SubmitForm (assembleContact form.name form.number form.email) model.api), value "+" ] [ text "+" ]
        , button [ id "phonebook__button", preventDefaultOn "click" (JD.map alwaysPreventDefault (JD.succeed (SubmitForm (assembleContact form.name form.number form.email) api))), value "+" ] [ text "+" ]
        ]


viewInput : String -> String -> String -> String -> String -> (String -> msg) -> Html msg
viewInput t t_ i p v toMsg =
    div [ class "phonebook__input clearfix" ]
        [ label [ for i, class "phonebook__label" ] [ text t ]
        , input [ type_ t_, id i, placeholder p, value v, onInput toMsg ] []
        , br [] []
        ]


assembleContact : String -> String -> String -> Contact
assembleContact name number email =
    { id_ = 0
    , name = name
    , number = number
    , email = email
    }



-- HTTP


readContacts : String -> Cmd Msg
readContacts api =
    Http.get
        { url = api
        , expect = Http.expectJson GotContacts contactListDecoder
        }


contactDecoder : Decoder Contact
contactDecoder =
    map4 Contact
        (field "id" JD.int)
        (field "name" JD.string)
        (field "number" JD.string)
        (field "email" JD.string)


contactListDecoder : Decoder (List Contact)
contactListDecoder =
    JD.list contactDecoder


contactEncoder : Contact -> Value
contactEncoder contact =
    object
        [ ( "name", JE.string contact.name )
        , ( "number", JE.string contact.number )
        , ( "email", JE.string contact.email )
        ]



-- MAYBES AND HELPERS
-- Not necessary atm


checkContact : Maybe Contact -> Contact
checkContact maybeContact =
    case maybeContact of
        Just contact ->
            contact

        Nothing ->
            { id_ = 404404
            , name = "No contacts to display"
            , number = "098 404 404"
            , email = "get.some@friends.com"
            }



-- Not necessary atm


checkEmail : Maybe String -> String
checkEmail maybeEmail =
    case maybeEmail of
        Just email ->
            email

        Nothing ->
            ""


alwaysPreventDefault : msg -> ( msg, Bool )
alwaysPreventDefault msg =
    ( msg, True )
