@tool
extends EditorScenePostImport


# Called by the editor when a scene has this script set as the import script in the import tab.
func _post_import(scene: Node) -> Object:
	# Modify the contents of the scene upon import.
	iterate(scene)
	
	return scene # Return the modified root node when you're done.


func iterate(main_node: Node) -> void:
	if main_node != null:
		var scene_kids_array: Array[Node] = main_node.get_children()
		
		for scene_kid in scene_kids_array:
			if scene_kid is MeshInstance3D:
				process_tag(scene_kid, main_node)


func process_tag(child_mesh: Node3D, _main_parent_node: Node3D) -> void:
	if (not child_mesh.get_meta_list().is_empty()) and child_mesh.get_meta("extras"):
		var child_tag_dict: Dictionary = child_mesh.get_meta("extras")
		# BUILDING
		if child_tag_dict.has("is_building"):
			process_asset_tag(child_mesh, "building")
		# WALL
		elif child_tag_dict.has("is_wall"):
			process_asset_tag(child_mesh, "wall")
		# ROAD
		elif child_tag_dict.has("is_road"):
			process_asset_tag(child_mesh, "road")
		# CUSTOM
		elif child_tag_dict.has("is_custom"):
			if child_tag_dict.has("custom_string"):
				var custom_string: String = child_tag_dict["custom_string"]
				process_asset_tag(child_mesh, custom_string)
				
		## StaticBody3D
		#elif child_tag_dict.has("is_static_body"):
			#process_static_body(child_mesh, main_parent_node)
		## CharacterBody3D
		#elif child_tag_dict.has("is_character_body"):
			#process_character_body(child_mesh, main_parent_node)
		## RigidBody3D
		#elif child_tag_dict.has("is_rigid_body"):
			#process_rigid_body(child_mesh, main_parent_node)
		## Area3D
		#elif child_tag_dict.has("is_area_3d"):
			#process_area_3d(child_mesh, main_parent_node)
		## Navigation Mesh
		#elif child_tag_dict.has("is_navmesh"):
			#process_navigation_mesh(child_mesh, main_parent_node)
		## CollisionShape3D
		#elif child_tag_dict.has("is_collision_shape"):
			##process_collision_shape(child_mesh, main_parent_node, child_tag_dict)
			#pass


func process_asset_tag(main_mesh: MeshInstance3D, type: String) -> void:
	for mesh_child in main_mesh.get_children():
		if mesh_child is StaticBody3D:
			print("%s is StaticBody3D - %s" % [mesh_child, type])
			
			mesh_child.add_to_group(type , true)
			#mesh_child.owner = main_mesh # .edited_scene_root
		else:
			print("%s is NOT StaticBody3D" % [mesh_child])


func process_static_body(main_mesh: MeshInstance3D, parent_node: Node3D) -> void:
	var original_mesh_name := main_mesh.name
	
	var new_static_body := StaticBody3D.new()
	new_static_body.name = "%s_StaticBody" % [original_mesh_name]
	
	process_main_mesh_parenting(new_static_body, main_mesh, parent_node)


func process_character_body(main_mesh: MeshInstance3D, parent_node: Node3D) -> void:
	var original_mesh_name := main_mesh.name
	
	var new_character_body := CharacterBody3D.new()
	new_character_body.name = "%s_CharacterBody" % [original_mesh_name]
	
	process_main_mesh_parenting(new_character_body, main_mesh, parent_node)


func process_rigid_body(main_mesh: MeshInstance3D, parent_node: Node3D) -> void:
	var original_mesh_name := main_mesh.name # .to_pascal_case()
	
	var new_rigid_body := RigidBody3D.new()
	new_rigid_body.name = "%s_CharacterBody" % [original_mesh_name]
	
	## Apply RigidBody properties
	apply_rigid_body_properties(main_mesh, new_rigid_body)
	
	process_main_mesh_parenting(new_rigid_body, main_mesh, parent_node)


func apply_rigid_body_properties(main_mesh: MeshInstance3D, rigid_body: RigidBody3D) -> void:
	if (not main_mesh.get_meta_list().is_empty()) and main_mesh.get_meta("extras"):
		var main_mesh_tag_dict: Dictionary = main_mesh.get_meta("extras")
		# MASS
		if main_mesh_tag_dict.has("rigid_body_mass"):
			rigid_body.mass = main_mesh_tag_dict["rigid_body_mass"]
		# CENTER OF MASS MODE
		if main_mesh_tag_dict.has("rigid_body_center_of_mass_mode"):
			match main_mesh_tag_dict["rigid_body_center_of_mass_mode"]:
				"AUTO":
					rigid_body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_AUTO
				"CUSTOM": 
					rigid_body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		# CENTER OF MASS
		if main_mesh_tag_dict.has("rigid_body_center_of_mass"):
			var center_of_mass_array: Array = main_mesh_tag_dict["rigid_body_center_of_mass"]
			rigid_body.center_of_mass = Vector3(center_of_mass_array[0], center_of_mass_array[1], center_of_mass_array[2])
			
		if main_mesh_tag_dict.has("physics_material_override_toggle"):
			var physics_material_override_toggle: bool = main_mesh_tag_dict["physics_material_override_toggle"]
			if physics_material_override_toggle:
				var new_physics_material := PhysicsMaterial.new()
				if main_mesh_tag_dict.has("physics_material_friction"):
					new_physics_material.friction = main_mesh_tag_dict["physics_material_friction"]
				if main_mesh_tag_dict.has("physics_material_rough"):
					new_physics_material.rough = main_mesh_tag_dict["physics_material_rough"]
				if main_mesh_tag_dict.has("physics_material_bounce"):
					new_physics_material.bounce = main_mesh_tag_dict["physics_material_bounce"]
				if main_mesh_tag_dict.has("physics_material_absorbent"):
					new_physics_material.absorbent = main_mesh_tag_dict["physics_material_absorbent"]
					
				rigid_body.physics_material_override = new_physics_material
			else:
				rigid_body.physics_material_override = null
				
func process_area_3d(main_mesh: MeshInstance3D, parent_node: Node3D) -> void:
	var original_mesh_name := main_mesh.name # .to_pascal_case()
	
	# Creating an Area3D
	var new_area_3d := Area3D.new()
	new_area_3d.name = "%s_Area3D" % [original_mesh_name]
	
	apply_area_3d_properties(main_mesh, new_area_3d)
	
	process_main_mesh_parenting(new_area_3d, main_mesh, parent_node)
	
	##NOTICE: REMEMBER TO DELETE THE MESH
	#main_mesh.queue_free()


func apply_area_3d_properties(main_mesh: MeshInstance3D, area_3d: Area3D) -> void:
	if (not main_mesh.get_meta_list().is_empty()) and main_mesh.get_meta("extras"):
		var main_mesh_tag_dict: Dictionary = main_mesh.get_meta("extras")
		# MASS
		if main_mesh_tag_dict.has("area_3d_monitoring"):
			area_3d.monitoring = main_mesh_tag_dict["area_3d_monitoring"]
		if main_mesh_tag_dict.has("area_3d_monitorable"):
			area_3d.monitorable = main_mesh_tag_dict["area_3d_monitorable"]


func process_navigation_mesh(mesh_node: MeshInstance3D, parent_node: Node3D) -> void:
	#print("%s is a Navigation Mesh!" % [mesh_node.name])
	
	var new_navigation_region := NavigationRegion3D.new()
	new_navigation_region.name = "%s_NavigationRegion" % [mesh_node.name]
	
	parent_node.add_child(new_navigation_region)
	new_navigation_region.owner = parent_node
	
	var new_navigation_mesh := NavigationMesh.new()
	new_navigation_mesh.create_from_mesh(mesh_node.mesh)
	
	new_navigation_region.transform = mesh_node.transform
	
	#print("NavRegion: %s - NavMesh: %s" % [new_navigation_region, new_navigation_mesh])
	
	new_navigation_region.navigation_mesh = new_navigation_mesh
	
	mesh_node.queue_free()


func process_main_mesh_parenting(new_body: Node3D, main_mesh: MeshInstance3D, main_parent_node: Node3D) -> void:
	var main_mesh_transform: Transform3D = main_mesh.transform
	main_parent_node.add_child(new_body)
	new_body.owner = main_parent_node
	new_body.transform = main_mesh_transform
	
	main_mesh.owner = null
	main_mesh.reparent(new_body, false)
	main_mesh.owner = main_parent_node
	main_mesh.transform = Transform3D.IDENTITY
	
	process_main_mesh_collision(main_mesh, new_body, main_parent_node)


func process_main_mesh_collision(main_mesh: MeshInstance3D, main_mesh_parent: Node3D, main_parent_node: Node3D) -> void:
	## An array to keep track of the main mesh's children
	var main_mesh_children_array: Array = main_mesh.get_children()
	# here we want to be sure that if the children are not MeshInstances we create a single CollisionShape from the mesh still
	var actual_mesh_children_array: Array[MeshInstance3D] = []
	for mesh_child in main_mesh_children_array:
		if mesh_child is MeshInstance3D:
			actual_mesh_children_array.append(mesh_child)
			
			var new_collision_shape: CollisionShape3D = create_collision_shape(mesh_child, main_mesh_parent)
			new_collision_shape.owner = main_parent_node
			
			mesh_child.queue_free()
	
	# In case no meshes were found we create a single CollisionShape based on the main mesh's geometry
	if actual_mesh_children_array.is_empty():
		var new_collision_shape: CollisionShape3D = create_collision_shape(main_mesh, main_mesh_parent)
		new_collision_shape.owner = main_parent_node


func create_collision_shape(main_mesh: MeshInstance3D, main_mesh_parent: Node3D) -> CollisionShape3D:
	var new_collision_shape := CollisionShape3D.new()
	new_collision_shape.name = "%s_CollisionShape" % [main_mesh.name]
	main_mesh_parent.add_child(new_collision_shape)
	
	if (not main_mesh.get_meta_list().is_empty()) and main_mesh.get_meta("extras"):
		var main_mesh_tag_dict: Dictionary = main_mesh.get_meta("extras")
		if main_mesh_tag_dict.has("collision_type"):
			match main_mesh_tag_dict["collision_type"]:
				"NO_COL":
					print("No collision on %s!" % [main_mesh.name])
				"CONVEX":
					new_collision_shape.shape = process_convex_collision_shape(main_mesh)
					new_collision_shape.transform = main_mesh.transform
					#print("Convex collision shape on %s!" % [main_mesh.name])
				"CONCAVE":
					new_collision_shape.shape = process_concave_collision_shape(main_mesh)
					new_collision_shape.transform = main_mesh.transform
					#print("Concave collision shape on %s!" % [main_mesh.name])
				"PRIMITIVE":
					#var primitive_stats_dict: Dictionary = 
					process_primitive_collision_shape(main_mesh, new_collision_shape, main_mesh_tag_dict)
					#print("Primitive collision shape on %s!" % [main_mesh.name])
				_:
					## We shouldn't ever see this, but it's here just to be safe
					print("No collision data was found for %s" % [main_mesh.name])
					
	return new_collision_shape


func process_convex_collision_shape(main_mesh: MeshInstance3D) -> ConvexPolygonShape3D:
	return main_mesh.mesh.create_convex_shape(true, true)


func process_concave_collision_shape(main_mesh) -> ConcavePolygonShape3D:
	return main_mesh.mesh.create_trimesh_shape()


func process_primitive_collision_shape(primitive_mesh: MeshInstance3D, mesh_collision_shape: CollisionShape3D, primitive_mesh_tag_dict: Dictionary) -> void:
	if (not primitive_mesh_tag_dict.is_empty()):
		if primitive_mesh_tag_dict.has("primitive_collision_type"):
			match primitive_mesh_tag_dict["primitive_collision_type"]:
				"BOX":
					var aabb := primitive_mesh.get_aabb()
					var center = aabb.get_center()
					
					var new_box_shape := BoxShape3D.new()
					new_box_shape.size = aabb.size
					
					mesh_collision_shape.shape = new_box_shape
					mesh_collision_shape.rotation = primitive_mesh.rotation
					mesh_collision_shape.position = primitive_mesh.position + center
					
					#print("%s needs a box primitive collision shape! - parent: %s - AABB: %s" % [primitive_mesh.name, primitive_mesh_collision_parent.name, aabb])
					#print("%s - mesh collision shape: %s -> AABB Pos: %s & Size: %s - Box Center: %s" % [primitive_mesh.name, mesh_collision_shape.name, aabb.position, aabb.size, aabb.get_center()])
				"CYLINDER":
					print("%s needs a cylinder primitive collision shape! - mesh collision shape: %s" % [primitive_mesh.name, mesh_collision_shape.name])
				"SPHERE":
					print("%s needs a sphere primitive collision shape! - mesh collision shape: %s" % [primitive_mesh.name, mesh_collision_shape.name])


##I guess we can use this one for invisible walls
#func process_collision_shape(child_mesh: MeshInstance3D, main_parent_node: Node3D, child_mesh_tags_dict: Dictionary) -> void:
	#if child_mesh.get_parent().get_parent() is PhysicsBody3D:
		#print("%s -> Collision shape! -> Parent: %s - Main Parent: %s" % [child_mesh.name, child_mesh.get_parent().get_parent().name, main_parent_node])


#func process_mesh_children(main_mesh: MeshInstance3D, parent_node: Node3D) -> void:
	## we check if a main mesh has children and process their tags
	#if main_mesh.get_child_count() > 0:
		#var main_mesh_children_array: Array[Node] = main_mesh.get_children()
		#for kid in main_mesh_children_array:
			#if kid is MeshInstance3D:
				#process_tag(kid, parent_node)
