local sformat = string.format;
local strlen = string.len;

l_socket = l_socket or {};

function l_socket:init()
    print("l_socket init.")
	self._sequence = 0;
end

function l_socket:read_msg()
    local raw_msg = l_dbg:Revc();
    local t_list = {};
    local count = 0;
    if type(raw_msg) == "string" then
        -- print("==========================================================")
        -- print("debug> recv:", raw_msg);
        local tmsg_list = l_utily:split_raw_msg(raw_msg);
        for _, msg in ipairs(tmsg_list) do 
            local t_msg = l_utily:decode(msg);
            if t_msg then
                local info = {};
                info.t_msg = t_msg;
                info.msg = msg;
                count = count + 1;
                t_list[count] = info;
            end
        end
    end
    return t_list;
end

function l_socket:send_msg(t_msg)
    if t_msg then
        local _sequence = self._sequence + 1;
        t_msg["seq"] = _sequence;
        local msg = l_utily:encode(t_msg);
        if msg then
            self._sequence = _sequence;
            local nlen = strlen(msg);
            -- print("==========================================================")
            local raw_msg = sformat("Content-Length: %s\r\n\r\n%s", nlen, msg);
            -- print("debug> send:", raw_msg);
            l_dbg:Send(raw_msg);
        end
    end
end

function l_socket:disconnect()
    l_dbg:Detach();
end

function l_socket:terminated()
    local event = self:create_event("terminated");
    self:send_msg(event);
end

function l_socket:stop_on_event(reason)
    local event = self:create_event("stopped");
    event.body = 
    {
        reason = reason,
        threadId = 1,
    }
    self:send_msg(event);
end

function l_socket:new_seq()
	self._sequence = self._sequence + 1;
	return self._sequence;
end

function l_socket:check_seq(seq)
	return self._sequence == seq;
end

--[[
    interface ProtocolMessage {
        /** Sequence number. */
        seq: number;
        /** Message type.
            Values: 'request', 'response', 'event', etc.
        */
        type: string;
    }
    /** A client or server-initiated request. */
    interface Request extends ProtocolMessage {
        /** The command to execute. */
        command: string;
        /** Object containing arguments for the command. */
        arguments?: any;
    }
    /** Server-initiated event. */
    interface Event extends ProtocolMessage {
        /** Type of event. */
        event: string;
        /** Event-specific information. */
        body?: any;
    }
    /** Response to a request. */
    interface Response extends ProtocolMessage {
        /** Sequence number of the corresponding request. */
        request_seq: number;
        /** Outcome of the request. */
        success: boolean;
        /** The command requested. */
        command: string;
        /** Contains error message if success == false. */
        message?: string;
        /** Contains request result if success is true and optional error details if success is false. */
        body?: any;
    }
]]

function l_socket:create_event(sevent)
	local t_header = {};
	t_header["event"] = sevent;
	t_header["seq"] = 0;
	t_header["type"] = "event";
	
	return t_header;
end

function l_socket:create_request(command)
	local t_header = {};
	t_header["command"] = command;
	t_header["seq"] = 0;
	t_header["type"] = "request";
	
	return t_header;
end

function l_socket:create_response(command, request_seq, success)
	success = success or true;
	local t_header = {};
	t_header["command"] = command;
	t_header["seq"] = 0;
	t_header["request_seq"] = request_seq;
	t_header["type"] = "response";
	t_header["success"] = success;
	if not success then
		t_header["message"] = "something wrong happened!";
	end
	
	return t_header;
end

function l_socket:response_form_request(request, erromsg)
	local response = self:create_response(request.command, request.seq, true);
	if erromsg then
		response["success"] = false;
		response["message"] = erromsg;
	end
	return response;
end

return l_socket;
