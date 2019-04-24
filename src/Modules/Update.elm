module Update exposing (selectGroup, typesReceived)

import ESI exposing (..)
import Model exposing (..)
import State exposing (..)
import Task exposing (Task)


isSameCurrent { currentActive } i =
    case ( currentActive, i ) of
        ( Just entity, Just id ) ->
            getEntityMarketId entity == id

        _ ->
            False


selectGroup : Model -> Maybe Int -> ( Model, Cmd Msg )
selectGroup model id =
    case ( id, isTerminalGroup model id, isSameCurrent model id ) of
        ( Nothing, _, _ ) ->
            ( { model
                | currentList = State.selectRoot model
                , currentActive = Nothing
                , navigation = Nothing
              }
            , Cmd.none
            )

        ( _, _, True ) ->
            let
                parentId =
                    getEntityMarketParentId model.currentActive
            in
            case parentId of
                Just i ->
                    ( { model
                        | currentList = State.selectGroupsList model i
                        , currentActive = State.selectGroup model i
                        , navigation = State.buildNavigationList model i
                      }
                    , Cmd.none
                    )

                Nothing ->
                    selectGroup model Nothing

        ( Just i, False, _ ) ->
            ( { model
                | currentList = State.selectGroupsList model i
                , currentActive = State.selectGroup model i
                , navigation = State.buildNavigationList model i
              }
            , Cmd.none
            )

        ( Just i, True, _ ) ->
            let
                selectedTypes =
                    State.selectTypesList model i
            in
            case selectedTypes of
                Just types ->
                    ( { model
                        | currentList = State.selectTypesList model i
                        , currentActive = State.selectGroup model i
                        , navigation = State.buildNavigationList model i
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( { model
                        | currentList = Nothing
                        , currentActive = State.selectGroup model i
                        , navigation = State.buildNavigationList model i
                      }
                    , Task.attempt TypesReceived <| ESI.getTypes i
                    )


typesReceived model types =
    case types of
        Ok recived ->
            ( { model
                | marketTypes = State.appendTypes model.marketTypes recived
                , currentList = Just <| EntityListTypes recived
              }
            , Cmd.none
            )

        Err _ ->
            ( model, Cmd.none )
