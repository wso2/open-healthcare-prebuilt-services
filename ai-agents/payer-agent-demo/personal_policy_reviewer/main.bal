import ballerina/ai;
import ballerina/log;
import ballerina/http;

listener ai:Listener policyReviewerListener = new (listenOn = check http:getDefaultListener());

service /policyReviewer on policyReviewerListener {
    resource function post chat(@http:Payload ai:ChatReqMessage request) returns ai:ChatRespMessage|error {
        log:printInfo("Processing personal policy review chat request for session: " + request.sessionId);
        string stringResult = check _policyReviewerAgent.run(request.message, request.sessionId);
        log:printInfo("Successfully processed chat request for session: " + request.sessionId);
        return {message: stringResult};
    }
}
