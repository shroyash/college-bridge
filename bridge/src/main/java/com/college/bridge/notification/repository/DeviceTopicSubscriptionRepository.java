package com.college.bridge.notification.repository;

import com.college.bridge.notification.entity.DeviceTopicSubscription;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.List;

@Repository
public interface DeviceTopicSubscriptionRepository extends JpaRepository<DeviceTopicSubscription, Long> {

    @Query("select s.topic from DeviceTopicSubscription s where s.device.deviceId = :deviceId")
    List<String> findTopicsByDeviceId(@Param("deviceId") Long deviceId);

    @Transactional
    @Modifying(flushAutomatically = true)
    @Query("""
        DELETE FROM DeviceTopicSubscription dts
        WHERE dts.device.deviceId = :deviceId AND dts.topic IN :topics
    """)
    int deleteByDevice_DeviceIdAndTopicIn(@Param("deviceId") Long deviceId,
                                          @Param("topics") Collection<String> topics);

    @Transactional
    @Modifying(flushAutomatically = true)
    @Query("DELETE FROM DeviceTopicSubscription dts WHERE dts.device.deviceId = :deviceId")
    int deleteByDeviceId(@Param("deviceId") Long deviceId);
}
