#pragma once

#include "ofxiOS.h"
#include "ofxARKit.h"
#include "calcNormals.h"

class ofApp : public ofxiOSApp {
    
public:
    
    ofApp (ARSession * session);
    ofApp();
    ~ofApp ();
    
    void setup();
    void update();
    void draw();
    void exit();
    
    void touchDown(ofTouchEventArgs &touch);
    void deviceOrientationChanged(int newOrientation);
    
    ofTrueTypeFont font;
    ofCamera camera;

    
    /** SHADER SHIT **/
    
    ofShader camShader;
    
    //VERTEX SHADER
    std::string camVertex = STRINGIFY(
                                      
                                      attribute vec2 position;
                                      varying vec2 vUv;
                                      
                                      const vec2 scale = vec2(0.5,0.5);
                                      void main(){
                                          vUv = position.xy * scale + scale;
                                          gl_Position = vec4(position,0.0,1.0);
                                      }
                                      
                                      );
    
    //FRAGMENT SHADER
    std::string camFragment = STRINGIFY(
                                        precision highp float;
                                        varying vec2 vUv;
                                        uniform sampler2D tex;
                                        void main(){
                                            
                                            vec2 uv = vec2(vUv.s, 1.0 - vUv.t);
                                            
                                            vec4 _tex = texture2D(tex,uv);
                                            gl_FragColor = _tex;
                                        }
                                        );

    
    
    // ====== AR STUFF ======== //
    ARSession * session;
    ARRef processor;
    
    ofMesh mesh;
    bool bDrawTriangles{true};
    
    ofTrueTypeFont verandaFont;
    
    //From Zach ofxMeshUtils
    //ofZach/ofxMeshUtils/blob/master/src/ofxMeshUtils.cpp#L32-L58
    void calcNormals(ofMesh &mesh) {
        for( int i=0; i < mesh.getVertices().size(); i++ ) mesh.addNormal(ofPoint(0,0,0));
        
        for( int i=0; i < mesh.getIndices().size(); i+=3 ){
            const int ia = mesh.getIndices()[i];
            const int ib = mesh.getIndices()[i+1];
            const int ic = mesh.getIndices()[i+2];
            
            ofVec3f e1 = mesh.getVertices()[ia] - mesh.getVertices()[ib];
            ofVec3f e2 = mesh.getVertices()[ic] - mesh.getVertices()[ib];
            ofVec3f no = e2.cross( e1 );
            
            // depending on your clockwise / winding order, you might want to reverse the e2 / e1 above if your normals are flipped.
            
            mesh.getNormals()[ia] += no;
            mesh.getNormals()[ib] += no;
            mesh.getNormals()[ic] += no;
        }
    }
    
    ofVec3f calculateCenter(ofMeshFace *face) {
        int lastPointIndex{3};
        ofVec3f result;
        for (unsigned int i = 0; i < 3; i++){
            result += face->getVertex(i);
        }
        result /= lastPointIndex;
        return result;
    }

    
    bool bDrawNormals{false};
    const float normalSize{0.01};
    void drawFaceMeshNormals(ofMesh mesh);
    
    std::vector<ofMesh> faceMeshes;
    std::vector<std::pair<ofMesh, ofMatrix4x4>> faceMeshesMatrix;
    const size_t maxTrailCount = 50;
};
