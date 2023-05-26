/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/javafx/FXMain.java to edit this template
 */
package Project;

import java.io.File;
import java.util.ArrayList;
import javafx.application.Application;
import static javafx.application.Application.launch;
import javafx.event.ActionEvent;
import javafx.event.EventHandler;
import javafx.scene.Scene;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.Button;
import javafx.scene.layout.Pane;
import javafx.scene.layout.StackPane;
import javafx.scene.paint.Color;
import javafx.stage.Stage;
import java.util.Collections;
import javafx.stage.FileChooser;

/**
 *
 * @author Hossa
 */
public class Test extends Application {

    @Override
    public void start(Stage primaryStage) {
        
                FileChooser fileChooser = new FileChooser();
        fileChooser.setTitle("Open MDL File");

        // Set the file extension filter
        FileChooser.ExtensionFilter extFilter = new FileChooser.ExtensionFilter("MDL files (.mdl)", ".mdl");
        fileChooser.getExtensionFilters().add(extFilter);

        // Show the file chooser dialog and get the selected file
        File selectedFile = fileChooser.showOpenDialog(primaryStage);

        
        
        
                ArrayList<Block> blocks = new ArrayList<Block>( );
                    Reader.read_file(blocks,selectedFile);
                    
     Collections.sort(blocks);
     blocks.get(2).print();
        Canvas canvas = new Canvas(8000, 4000);
        GraphicsContext gc = canvas.getGraphicsContext2D();
                for (int m = 0; m < blocks.size(); m++) {
            blocks.get(m).draw(gc);
            
        }
                   

     Block.drawLines(gc, blocks);

     Block.drawBranchLines(gc, blocks);
    Pane root = new Pane(canvas);

        // create a scene with the container as the root node
        Scene scene = new Scene(root, 400, 200);
//
//        // set the stage title and show it
        primaryStage.setTitle("Simulink Model");
        primaryStage.setScene(scene);
        primaryStage.show();
    
    }

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        launch(args);
    }

}
