#include "ofApp.h"
using namespace ofxARKit::common;
//--------------------------------------------------------------
ofApp :: ofApp (ARSession * session){
    ARFaceTrackingConfiguration *configuration = [ARFaceTrackingConfiguration new];
    
    [session runWithConfiguration:configuration];
    
    this->session = session;
}

ofApp::ofApp(){}

//--------------------------------------------------------------
ofApp :: ~ofApp () {
}

vector <ofPrimitiveMode> primModes;
int currentPrimIndex;

//--------------------------------------------------------------
void ofApp::setup() {
    ofBackground(127);
    ofSetFrameRate(60);
    ofEnableDepthTest();

    processor = ARProcessor::create(session);
    processor->setup();

    ofSetFrameRate(60);
    
    camShader.setupShaderFromSource(GL_VERTEX_SHADER, camVertex);
    camShader.setupShaderFromSource(GL_FRAGMENT_SHADER, camFragment);
    camShader.linkProgram();
}

//--------------------------------------------------------------
void ofApp::update(){
    processor->update();
    processor->updateFaces();
    
    for (auto & face : processor->getFaces()){
        ofMesh localMesh;
        localMesh.addVertices(face.vertices);
        localMesh.addTexCoords(face.uvs);
        localMesh.addIndices(face.indices);
        
        ofMatrix4x4 currentTransform = toMat4(face.raw.transform);
        
        faceMeshes.push_back(localMesh);
        faceMeshesMatrix.push_back({localMesh, currentTransform});
        
        if (faceMeshes.size() > 120){
            faceMeshesMatrix.erase(faceMeshesMatrix.begin());
            faceMeshes.erase(faceMeshes.begin());
        }
    }
    
   // cout << faceMeshes.size() << endl;
}

void drawEachTriangle(ofMesh faceMesh) {
    // Determine bounding box
       ofVec3f minVertex = faceMesh.getVertex(0);
       ofVec3f maxVertex = faceMesh.getVertex(0);
       for (auto& vertex : faceMesh.getVertices()) {
           minVertex.x = std::min(minVertex.x, vertex.x);
           minVertex.y = std::min(minVertex.y, vertex.y);
           minVertex.z = std::min(minVertex.z, vertex.z);
           
           maxVertex.x = std::max(maxVertex.x, vertex.x);
           maxVertex.y = std::max(maxVertex.y, vertex.y);
           maxVertex.z = std::max(maxVertex.z, vertex.z);
       }

       ofPushStyle();
       for (auto face : faceMesh.getUniqueFaces()) {
           // Average the positions of the triangle's vertices
           ofVec3f avgPosition = (face.getVertex(0) + face.getVertex(1) + face.getVertex(2)) / 3.0;

           // Normalize the average position within the bounding box
           float normalizedX = ofMap(avgPosition.x, minVertex.x, maxVertex.x, 0, 1);
           float normalizedY = ofMap(avgPosition.y, minVertex.y, maxVertex.y, 0, 1);
           
           ofSetColor(ofColor::fromHsb(normalizedX * 255, 255, normalizedY * 255));
           ofDrawTriangle(face.getVertex(0), face.getVertex(1), face.getVertex(2));
       }
       ofPopStyle();
}

void drawFaceCircles(ofMesh faceMesh) {
    ofPushStyle();
    ofSetColor(0, 0, 255);
    auto verts = faceMesh.getVertices();
    for (int i = 0; i < verts.size(); ++i){
        ofDrawCircle(verts[i] * ofVec3f(1, 1, 1), 0.001);
    }
    ofPopStyle();
}

void ofApp::drawFaceMeshNormals(ofMesh mesh) {
    vector<ofMeshFace> faces = mesh.getUniqueFaces();
    ofMeshFace face;
    ofVec3f c, n;
    ofPushStyle();
    ofSetColor(ofColor::white);
    for(unsigned int i = 0; i < faces.size(); i++){
        face = faces[i];
        c = calculateCenter(&face);
        n = face.getFaceNormal();
        ofDrawLine(c.x, c.y, c.z, c.x+n.x*normalSize, c.y+n.y*normalSize, c.z+n.z*normalSize);
    }
    ofPopStyle();
}

//--------------------------------------------------------------
void ofApp::draw() {
    
    ofDisableDepthTest();
    processor->draw();
    
    camera.begin();
    processor->setARCameraMatrices();
    
    // USED FOR MAPPING FACETEX TO MESH //
    CVOpenGLESTextureRef _tex = processor->getCameraTexture();
    GLuint texID = CVOpenGLESTextureGetName(_tex);
   
    for (const auto &[mesh, transform] : faceMeshesMatrix) {

        // basic coloring this looks bad bear with me it's just for testing lmaoooo

        float time = ofGetElapsedTimef(); // Get the elapsed time in seconds
        int red = (sin(time*2) + 1) * 127.5; // Values between 0 and 255
        int green = (sin(time*2 + PI / 2) + 1) * 127.5; // Offset by PI/2 to create variation
        int blue = (sin(time*2 + PI) + 1) * 90.0; // Offset by PI to create variation

        ofSetColor(red, green, blue); // Set the color
        ofPushMatrix();
        ofMultMatrix(transform);
        mesh.drawWireframe();
        ofPopMatrix();
    }
    
    
    camera.end();
}
    
void ofApp::exit() {}

void ofApp::touchDown(ofTouchEventArgs &touch){
    if (touch.x > ofGetWidth() * 0.5) {
        bDrawTriangles = !bDrawTriangles;
    } else if (touch.x < ofGetWidth() * 0.5) {
        bDrawNormals = !bDrawNormals;
    }
}

void ofApp::deviceOrientationChanged(int newOrientation){
    processor->deviceOrientationChanged(newOrientation);
}


