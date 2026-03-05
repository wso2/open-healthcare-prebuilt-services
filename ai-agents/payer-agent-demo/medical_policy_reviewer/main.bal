import ballerina/ai;
import ballerina/log;
import ballerina/http;

listener ai:Listener medicalPolicyReviewerListener = new (listenOn = check http:getDefaultListener());

service /medicalPolicyReviewer on medicalPolicyReviewerListener {
    resource function post chat(@http:Payload ai:ChatReqMessage request) returns ai:ChatRespMessage|error {
        log:printInfo("Processing medical policy review chat request for session: " + request.sessionId);
        string stringResult = check _medicalPolicyReviewerAgent.run(request.message, request.sessionId);
        log:printInfo("Successfully processed chat request for session: " + request.sessionId);
        return {message: stringResult};
    }
}
