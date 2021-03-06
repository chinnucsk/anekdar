-module(pub_http_handler).
-behaviour(cowboy_http_handler).
-export([init/3, handle/2, terminate/2]).

init({_Any, http}, Req, []) ->
    {ok, Req, undefined}.

handle(Req, State) ->
    Reply = case cowboy_http_req:method(Req) of
        {'POST', Req2} ->
            % read message body
            {ok, Message, Req3} = cowboy_http_req:body(Req2),
            % get channels from url
            {Params, Req4} = cowboy_http_req:binding(channels, Req3), 
            Channels = re:split(Params, ","),
            publish(Channels, Message, Req4);
        {_, Req2} ->
            {ok, Req3} = cowboy_http_req:reply(404, [], <<"Not Found">>, Req2),
            Req3
        end,
        {ok, Reply, State}.

terminate(_Req, _State) ->
    ok.

publish(Channels, Message, Req) ->
    Counts = pub_sub_manager:mpub(Channels, Message),
    {ok, Req2} = cowboy_http_req:reply(200,
        [{'Content-Type', <<"application/json">>},{<<"Access-Control-Allow-Origin">>, <<"*">>}],
            jiffy:encode({Counts}), Req),
    Req2.
