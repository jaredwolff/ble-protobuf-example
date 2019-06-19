/*eslint-disable block-scoped-var, no-redeclare, no-control-regex, no-prototype-builtins*/
(function(global, factory) { /* global define, require, module */

    /* AMD */ if (typeof define === 'function' && define.amd)
        define(["protobufjs/minimal"], factory);

    /* CommonJS */ else if (typeof require === 'function' && typeof module === 'object' && module && module.exports)
        module.exports = factory(require("protobufjs/minimal"));

})(this, function($protobuf) {
    "use strict";

    // Common aliases
    var $Reader = $protobuf.Reader, $Writer = $protobuf.Writer, $util = $protobuf.util;
    
    // Exported root namespace
    var $root = $protobuf.roots["default"] || ($protobuf.roots["default"] = {});
    
    $root.event = (function() {
    
        /**
         * Properties of an event.
         * @exports Ievent
         * @interface Ievent
         * @property {event.event_type|null} [type] event type
         * @property {string|null} [message] event message
         */
    
        /**
         * Constructs a new event.
         * @exports event
         * @classdesc Represents an event.
         * @implements Ievent
         * @constructor
         * @param {Ievent=} [properties] Properties to set
         */
        function event(properties) {
            if (properties)
                for (var keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }
    
        /**
         * event type.
         * @member {event.event_type} type
         * @memberof event
         * @instance
         */
        event.prototype.type = 0;
    
        /**
         * event message.
         * @member {string} message
         * @memberof event
         * @instance
         */
        event.prototype.message = "";
    
        /**
         * Creates a new event instance using the specified properties.
         * @function create
         * @memberof event
         * @static
         * @param {Ievent=} [properties] Properties to set
         * @returns {event} event instance
         */
        event.create = function create(properties) {
            return new event(properties);
        };
    
        /**
         * Encodes the specified event message. Does not implicitly {@link event.verify|verify} messages.
         * @function encode
         * @memberof event
         * @static
         * @param {Ievent} message event message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        event.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.type != null && message.hasOwnProperty("type"))
                writer.uint32(/* id 1, wireType 0 =*/8).int32(message.type);
            if (message.message != null && message.hasOwnProperty("message"))
                writer.uint32(/* id 2, wireType 2 =*/18).string(message.message);
            return writer;
        };
    
        /**
         * Encodes the specified event message, length delimited. Does not implicitly {@link event.verify|verify} messages.
         * @function encodeDelimited
         * @memberof event
         * @static
         * @param {Ievent} message event message or plain object to encode
         * @param {$protobuf.Writer} [writer] Writer to encode to
         * @returns {$protobuf.Writer} Writer
         */
        event.encodeDelimited = function encodeDelimited(message, writer) {
            return this.encode(message, writer).ldelim();
        };
    
        /**
         * Decodes an event message from the specified reader or buffer.
         * @function decode
         * @memberof event
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @param {number} [length] Message length if known beforehand
         * @returns {event} event
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        event.decode = function decode(reader, length) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            var end = length === undefined ? reader.len : reader.pos + length, message = new $root.event();
            while (reader.pos < end) {
                var tag = reader.uint32();
                switch (tag >>> 3) {
                case 1:
                    message.type = reader.int32();
                    break;
                case 2:
                    message.message = reader.string();
                    break;
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };
    
        /**
         * Decodes an event message from the specified reader or buffer, length delimited.
         * @function decodeDelimited
         * @memberof event
         * @static
         * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
         * @returns {event} event
         * @throws {Error} If the payload is not a reader or valid buffer
         * @throws {$protobuf.util.ProtocolError} If required fields are missing
         */
        event.decodeDelimited = function decodeDelimited(reader) {
            if (!(reader instanceof $Reader))
                reader = new $Reader(reader);
            return this.decode(reader, reader.uint32());
        };
    
        /**
         * Verifies an event message.
         * @function verify
         * @memberof event
         * @static
         * @param {Object.<string,*>} message Plain object to verify
         * @returns {string|null} `null` if valid, otherwise the reason why it is not
         */
        event.verify = function verify(message) {
            if (typeof message !== "object" || message === null)
                return "object expected";
            if (message.type != null && message.hasOwnProperty("type"))
                switch (message.type) {
                default:
                    return "type: enum value expected";
                case 0:
                case 1:
                    break;
                }
            if (message.message != null && message.hasOwnProperty("message"))
                if (!$util.isString(message.message))
                    return "message: string expected";
            return null;
        };
    
        /**
         * Creates an event message from a plain object. Also converts values to their respective internal types.
         * @function fromObject
         * @memberof event
         * @static
         * @param {Object.<string,*>} object Plain object
         * @returns {event} event
         */
        event.fromObject = function fromObject(object) {
            if (object instanceof $root.event)
                return object;
            var message = new $root.event();
            switch (object.type) {
            case "command":
            case 0:
                message.type = 0;
                break;
            case "response":
            case 1:
                message.type = 1;
                break;
            }
            if (object.message != null)
                message.message = String(object.message);
            return message;
        };
    
        /**
         * Creates a plain object from an event message. Also converts values to other types if specified.
         * @function toObject
         * @memberof event
         * @static
         * @param {event} message event
         * @param {$protobuf.IConversionOptions} [options] Conversion options
         * @returns {Object.<string,*>} Plain object
         */
        event.toObject = function toObject(message, options) {
            if (!options)
                options = {};
            var object = {};
            if (options.defaults) {
                object.type = options.enums === String ? "command" : 0;
                object.message = "";
            }
            if (message.type != null && message.hasOwnProperty("type"))
                object.type = options.enums === String ? $root.event.event_type[message.type] : message.type;
            if (message.message != null && message.hasOwnProperty("message"))
                object.message = message.message;
            return object;
        };
    
        /**
         * Converts this event to JSON.
         * @function toJSON
         * @memberof event
         * @instance
         * @returns {Object.<string,*>} JSON object
         */
        event.prototype.toJSON = function toJSON() {
            return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
        };
    
        /**
         * event_type enum.
         * @name event.event_type
         * @enum {string}
         * @property {number} command=0 command value
         * @property {number} response=1 response value
         */
        event.event_type = (function() {
            var valuesById = {}, values = Object.create(valuesById);
            values[valuesById[0] = "command"] = 0;
            values[valuesById[1] = "response"] = 1;
            return values;
        })();
    
        return event;
    })();

    return $root;
});
